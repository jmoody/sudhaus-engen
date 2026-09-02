#!/usr/bin/env bash

set -euo pipefail

readonly CCR_BOT_LOGIN="copilot-pull-request-reviewer[bot]"
readonly CCR_BOT_GRAPHQL_LOGIN="copilot-pull-request-reviewer"
readonly CCR_TIMELINE_LOGIN="Copilot"
readonly DEFAULT_TIMEOUT=900
readonly DEFAULT_INTERVAL=30

usage() {
  cat << EOF
Usage: $0 <command> [args]

Drive the iterative Copilot Code Review (CCR) loop for a pull request.

Commands:
  review <pr> [--timeout N] [--interval N]
                                        Capture the current review baseline, request CCR, then wait
                                        for the next review and list unresolved threads. Preferred:
                                        this snapshots the baseline before requesting, avoiding a race.
  request <pr>                          Request CCR and verify the timeline event.
  latest <pr>                           Print the submitted_at of the latest CCR review (empty if none).
  wait <pr> [--since TS] [--timeout N] [--interval N]
                                        Block until a CCR review newer than the baseline lands,
                                        then list unresolved threads. Baseline is --since, or the
                                        latest existing CCR review at invocation. When driving the
                                        loop manually, capture --since with 'latest' before 'request'.
  threads <pr>                          List unresolved CCR review threads as JSON lines.
  capture <pr>                          List all CCR review threads (resolved and unresolved) as
                                        JSON lines for retrospective capture.
  reply <thread-id> <message>           Reply to a review thread.
  resolve <thread-id>                   Resolve a review thread.

Options:
  -h, --help                            Show this help message.

Requires: gh (authenticated). Repository is auto-detected via gh.
EOF
}

log_info() {
  echo "[INFO] $*"
}

log_error() {
  echo "[ERROR] $*" >&2
}

repo_slug() {
  gh repo view --json nameWithOwner --jq .nameWithOwner
}

require_positive_int() {
  local name="$1"
  local value="$2"
  if [[ ! "${value}" =~ ^[1-9][0-9]*$ ]]; then
    log_error "${name} must be a positive integer, got '${value}'."
    return 1
  fi
}

latest_review_request_id() {
  local repo="$1"
  local pr="$2"
  gh api "repos/${repo}/issues/${pr}/timeline" --paginate \
    --jq ".[] | select(.event==\"review_requested\" and .requested_reviewer.login==\"${CCR_TIMELINE_LOGIN}\") | .id" \
    | tail -n 1
}

latest_review_ts() {
  local repo="$1"
  local pr="$2"
  gh api "repos/${repo}/pulls/${pr}/reviews" --paginate \
    --jq ".[] | select(.user.login==\"${CCR_BOT_LOGIN}\") | .submitted_at" | tail -n 1
}

ccr_threads() {
  local repo="$1"
  local pr="$2"
  local owner="${repo%%/*}"
  local name="${repo##*/}"
  # shellcheck disable=SC2016
  gh api graphql --paginate -f query='
    query($owner:String!,$name:String!,$pr:Int!,$endCursor:String){
      repository(owner:$owner,name:$name){
        pullRequest(number:$pr){
          reviewThreads(first:100, after:$endCursor){
            pageInfo{ hasNextPage endCursor }
            nodes{
              id isResolved
              comments(first:1){ nodes{ author{ login } path line body } }
            }
          }
        }
      }
    }' -f owner="$owner" -f name="$name" -F pr="$pr" \
    --jq ".data.repository.pullRequest.reviewThreads.nodes[]
      | select(.comments.nodes[0].author.login==\"${CCR_BOT_GRAPHQL_LOGIN}\")
      | {id, path: .comments.nodes[0].path, line: .comments.nodes[0].line, isResolved, body: .comments.nodes[0].body}" \
    | jq -c '.'
}

unresolved_threads() {
  local repo="$1"
  local pr="$2"
  ccr_threads "${repo}" "${pr}" \
    | jq -c 'select(.isResolved==false) | {id, path, line, body}'
}

long_optarg() {
  local name="$1"
  local argc="$2"
  local idx="$3"
  local value="$4"
  if (( idx > argc )); then
    log_error "--${name} requires a value."
    return 1
  fi
  if [[ "${value}" == -* ]]; then
    log_error "--${name} requires a value, got option '${value}'."
    return 1
  fi
  printf '%s' "${value}"
}

parse_loop_opts() {
  local allow_since="$1"
  shift
  OPT_PR="${1:?pull request number required}"
  shift
  OPT_SINCE=""
  OPT_SINCE_SET=false
  OPT_TIMEOUT="${DEFAULT_TIMEOUT}"
  OPT_INTERVAL="${DEFAULT_INTERVAL}"

  local argc=$#
  local opt
  local OPTIND=1
  local next
  while getopts ":t:i:s:h-:" opt; do
    case "${opt}" in
      t) OPT_TIMEOUT="${OPTARG}" ;;
      i) OPT_INTERVAL="${OPTARG}" ;;
      s) OPT_SINCE="${OPTARG}"; OPT_SINCE_SET=true ;;
      h) usage; exit 0 ;;
      -)
        case "${OPTARG}" in
          timeout) next="$(long_optarg timeout "${argc}" "${OPTIND}" "${!OPTIND-}")" || return 1
                   OPTIND=$(( OPTIND + 1 )); OPT_TIMEOUT="${next}" ;;
          timeout=*) OPT_TIMEOUT="${OPTARG#*=}" ;;
          interval) next="$(long_optarg interval "${argc}" "${OPTIND}" "${!OPTIND-}")" || return 1
                    OPTIND=$(( OPTIND + 1 )); OPT_INTERVAL="${next}" ;;
          interval=*) OPT_INTERVAL="${OPTARG#*=}" ;;
          since) next="$(long_optarg since "${argc}" "${OPTIND}" "${!OPTIND-}")" || return 1
                 OPTIND=$(( OPTIND + 1 )); OPT_SINCE="${next}"; OPT_SINCE_SET=true ;;
          since=*) OPT_SINCE="${OPTARG#*=}"; OPT_SINCE_SET=true ;;
          help) usage; exit 0 ;;
          *) log_error "Unknown option: --${OPTARG}"; return 1 ;;
        esac ;;
      :) log_error "Option -${OPTARG} requires a value."; return 1 ;;
      *) log_error "Invalid option: -${OPTARG}."; return 1 ;;
    esac
  done

  if [[ "${allow_since}" != true && "${OPT_SINCE_SET}" == true ]]; then
    log_error "--since is not valid for this command."
    return 1
  fi

  require_positive_int "--timeout" "${OPT_TIMEOUT}" || return 1
  require_positive_int "--interval" "${OPT_INTERVAL}" || return 1
}

cmd_request() {
  local pr="${1:?pull request number required}"
  local repo
  repo="$(repo_slug)"

  local before_id
  before_id="$(latest_review_request_id "${repo}" "${pr}")"
  gh api -X POST "repos/${repo}/pulls/${pr}/requested_reviewers" \
    -f "reviewers[]=${CCR_BOT_LOGIN}" > /dev/null

  local attempts=10
  local i
  for (( i = 0; i < attempts; i++ )); do
    sleep 3
    local now_id
    now_id="$(latest_review_request_id "${repo}" "${pr}")"
    if [[ -n "${now_id}" && "${now_id}" != "${before_id}" ]]; then
      log_info "CCR requested on ${repo}#${pr}; new review_requested event ${now_id} names ${CCR_TIMELINE_LOGIN}."
      return 0
    fi
  done

  log_error "CCR request not confirmed: no new ${CCR_TIMELINE_LOGIN} review_requested event after POST (last id: '${before_id:-none}')."
  return 1
}

cmd_latest() {
  local pr="${1:?pull request number required}"
  local repo
  repo="$(repo_slug)"
  latest_review_ts "${repo}" "${pr}"
}

cmd_wait() {
  parse_loop_opts true "$@" || return 1
  local pr="${OPT_PR}"
  local since="${OPT_SINCE}"
  local timeout="${OPT_TIMEOUT}"
  local interval="${OPT_INTERVAL}"
  local repo
  repo="$(repo_slug)"

  if [[ "${OPT_SINCE_SET}" == false ]]; then
    since="$(latest_review_ts "${repo}" "${pr}")"
  fi
  log_info "Waiting for a CCR review on ${repo}#${pr} newer than '${since:-<none>}' (timeout ${timeout}s)."

  local elapsed=0
  while (( elapsed < timeout )); do
    local latest
    latest="$(latest_review_ts "${repo}" "${pr}")"
    if [[ -n "${latest}" && ( -z "${since}" || "${latest}" > "${since}" ) ]]; then
      log_info "New CCR review submitted at ${latest}."
      local threads
      threads="$(unresolved_threads "${repo}" "${pr}")"
      if [[ -z "${threads}" ]]; then
        log_info "No unresolved CCR threads. Loop is complete."
      else
        log_info "Unresolved CCR threads:"
        echo "${threads}"
      fi
      return 0
    fi
    sleep "${interval}"
    elapsed=$(( elapsed + interval ))
  done

  log_error "Timed out after ${timeout}s waiting for a new CCR review."
  return 1
}

cmd_threads() {
  local pr="${1:?pull request number required}"
  local repo
  repo="$(repo_slug)"
  unresolved_threads "${repo}" "${pr}"
}

cmd_capture() {
  local pr="${1:?pull request number required}"
  local repo
  repo="$(repo_slug)"
  local threads
  threads="$(ccr_threads "${repo}" "${pr}")"
  if [[ -z "${threads}" ]]; then
    log_info "No CCR threads on ${repo}#${pr}; nothing to capture."
    return 0
  fi
  echo "${threads}"
}

cmd_review() {
  parse_loop_opts false "$@" || return 1
  local pr="${OPT_PR}"
  local timeout="${OPT_TIMEOUT}"
  local interval="${OPT_INTERVAL}"
  local repo
  repo="$(repo_slug)"

  local baseline
  baseline="$(latest_review_ts "${repo}" "${pr}")"
  cmd_request "${pr}"
  cmd_wait "${pr}" --since "${baseline}" --timeout "${timeout}" --interval "${interval}"
}

cmd_reply() {
  local thread="${1:?thread id required}"
  local message="${2:?reply message required}"
  # shellcheck disable=SC2016
  gh api graphql -f query='
    mutation($t:ID!,$b:String!){
      addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$t, body:$b}){
        comment{ id }
      }
    }' -f t="${thread}" -f b="${message}" --jq '.data.addPullRequestReviewThreadReply.comment.id' > /dev/null
  log_info "Replied to thread ${thread}."
}

cmd_resolve() {
  local thread="${1:?thread id required}"
  # shellcheck disable=SC2016
  gh api graphql -f query='
    mutation($t:ID!){
      resolveReviewThread(input:{threadId:$t}){ thread{ id isResolved } }
    }' -f t="${thread}" \
    --jq '.data.resolveReviewThread.thread | "resolved \(.id) isResolved=\(.isResolved)"'
}

main() {
  if [[ $# -eq 0 ]]; then
    usage
    exit 1
  fi

  local command="$1"
  shift

  case "${command}" in
    -h|--help|help) usage; exit 0 ;;
    request) cmd_request "$@" ;;
    latest) cmd_latest "$@" ;;
    wait) cmd_wait "$@" ;;
    review) cmd_review "$@" ;;
    threads) cmd_threads "$@" ;;
    capture) cmd_capture "$@" ;;
    reply) cmd_reply "$@" ;;
    resolve) cmd_resolve "$@" ;;
    *) log_error "Unknown command: ${command}"; usage; exit 1 ;;
  esac
}

main "$@"
