#!/usr/bin/env bash

set -euo pipefail

# compact-mode-check.sh computes an ACE-FCA compact-mode eligibility verdict for
# a GitHub issue. It parses referenced artifacts from the issue, counts merged
# PRs that touched those artifacts since the issue was filed (staleness drift),
# and evaluates risk-class signals. It prints a COMPACT_MODE: verdict line.
#
# The verdict is intentionally conservative: any drift, or an automatic
# risk-class signal, disqualifies compact mode and forces the full research +
# planning pass. Signal (b) is surfaced as an advisory the human confirms.

readonly PR_LIST_LIMIT=200

# Decision-output / open-ended-investigation verbs (risk-class signal a).
readonly RISK_VERBS='rank|score|recommend|compare|suggest|prioritize|estimate|research|investigate|spike'

# Decision-field names in the deliverable (risk-class signal c). Mirrors the
# field list in the ACE-FCA decision-output contract, plus the generic provenance /
# justification / confidence markers named in the agent persona.
readonly RISK_FIELDS='decision_basis|source_of_truth|success_probability|probability_adjustment_source|provenance|justification|confidence'

usage() {
  cat << EOF
Usage: $0 [OPTIONS] <issue-number>

Compute an ACE-FCA compact-mode eligibility verdict for a GitHub issue.

ARGUMENTS:
  <issue-number>       Numeric issue to evaluate.

OPTIONS:
  -r, --repo <owner/repo>  Repository (default: derived from 'gh repo view').
  -s, --since <YYYY-MM-DD>  Override the drift window start
                            (default: the issue's creation date).
  -h, --help               Show this help message.

Requires: gh (authenticated). Run from within the repository.
EOF
}

log_error() {
  echo "[ERROR] $*" >&2
}

log_warn() {
  echo "[WARN] $*" >&2
}

# long_optarg reads the space-separated value of a long option (e.g. the "foo"
# in "--repo foo"). It validates that a value is present and is not itself an
# option, then prints it. Args: name argc optind value.
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

# normalize_date strips any time component from an ISO-8601 / RFC3339 value,
# leaving a bare YYYY-MM-DD that GitHub's merged:>= search qualifier accepts.
normalize_date() {
  local raw="$1"
  printf '%s\n' "${raw%%T*}"
}

# parse_artifacts reads issue text on stdin and prints one referenced artifact
# per line, de-duplicated. Code paths are emitted verbatim; plan references in
# either 'plans/0NNN-slug' or bare '0NNN' form are normalized to '0NNN'.
parse_artifacts() {
  local text
  text="$(cat)"
  {
    grep -oE 'internal/[A-Za-z0-9_./-]+' <<< "$text" || true
    grep -oE '(script|docs)/[A-Za-z0-9_.-]+' <<< "$text" || true
    grep -oE '[A-Za-z0-9_./-]+\.(go|tf)' <<< "$text" || true
    grep -oE 'plans/0[0-9]{3}-[a-z0-9-]+' <<< "$text" | grep -oE '0[0-9]{3}' || true
    grep -oE '(^|[^0-9])0[0-9]{3}([^0-9]|$)' <<< "$text" | grep -oE '0[0-9]{3}' || true
  } | sort -u
}

# classify_artifact prints a "<kind>\t<value>" tuple describing how an artifact
# should be matched against a changed file:
#   dir    match any changed file under this package directory
#   plan   match any changed plan file carrying this 0NNN number
#   exact  match this exact path
classify_artifact() {
  local a="$1"
  if [[ "$a" =~ ^0[0-9]{3}$ ]]; then
    printf 'plan\t%s\n' "$a"
    return
  fi
  if [[ "$a" == internal/* ]]; then
    local last="${a##*/}"
    if [[ "$last" == *.* ]]; then
      printf 'dir\t%s\n' "$(dirname "$a")"
    else
      printf 'dir\t%s\n' "$a"
    fi
    return
  fi
  printf 'exact\t%s\n' "$a"
}

# file_matches_artifact returns 0 when changed file $1 matches classified
# artifact kind $2 / value $3.
file_matches_artifact() {
  local file="$1" kind="$2" value="$3"
  case "$kind" in
    dir) [[ "$file" == "$value"/* ]] ;;
    plan) [[ "$file" == *"plans/${value}"* ]] ;;
    exact) [[ "$file" == "$value" ]] ;;
    *) return 1 ;;
  esac
}

# risk_class_verbs prints each decision verb found in the issue title (or tool
# name) on stdin (risk-class signal a). The binding rule scopes this signal to
# the title/tool name, not the full body, so ordinary body prose like "compare
# the old and new values" does not force a planning pass. Text is tokenized on
# non-alphanumerics (so 'rank_event_priority' and 'ranking' both surface
# 'rank') and each token is prefix-matched against the verb list.
risk_class_verbs() {
  local text word verb
  text="$(tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' ' ')"
  {
    for word in $text; do
      for verb in ${RISK_VERBS//|/ }; do
        case "$word" in
          "$verb" | "$verb"[a-z0-9]*)
            printf '%s\n' "$verb"
            break
            ;;
        esac
      done
    done
  } | sort -u
}

# risk_class_fields prints each decision-field name found in the text on stdin
# (risk-class signal c).
risk_class_fields() {
  grep -oiwE "$RISK_FIELDS" | tr '[:upper:]' '[:lower:]' | sort -u || true
}

# risk_class_advisory prints a signal-(b) advisory match when a plan reference
# co-occurs with a metric-policy marker anywhere in the text on stdin. This is
# a fuzzy heuristic, so it is advisory only and never flips the verdict.
risk_class_advisory() {
  local text
  text="$(cat)"
  if grep -qE '0[0-9]{3}' <<< "$text" \
    && { grep -qiwE 'gate|policy|contract' <<< "$text" || grep -qF '§' <<< "$text"; }; then
    local marker
    marker="$(grep -oiwE 'gate|policy|contract' <<< "$text" | head -n1)"
    [[ -z "$marker" ]] && marker='§'
    printf 'plan reference near "%s"\n' "$marker"
  fi
}

# join_commas turns a newline-separated list on stdin into a comma-separated
# string with no leading/trailing commas.
join_commas() {
  tr '\n' ',' | sed 's/,*$//;s/^,*//'
}

# format_verdict prints the COMPACT_MODE verdict line(s) from the automatic
# signals. verbs and fields are newline-separated lists (empty means the signal
# did not fire); drift is an integer, the literal "inconclusive" (no parseable
# artifacts), or the literal "capped" (the merged-PR list hit the fetch cap, so
# staleness could not be established). since is the window start. Disqualifies on
# signal (a), signal (c), drift > 0, or a capped drift result. Signal (b) is
# advisory and is intentionally not an input here.
format_verdict() {
  local verbs="$1" fields="$2" drift="$3" since="$4"
  local -a reasons=()
  if [[ -n "$verbs" ]]; then
    reasons+=("risk-class signal (a): decision verb(s) $(join_commas <<< "$verbs")")
  fi
  if [[ -n "$fields" ]]; then
    reasons+=("risk-class signal (c): decision field(s) $(join_commas <<< "$fields")")
  fi
  if [[ "$drift" == "capped" ]]; then
    reasons+=("staleness indeterminate (merged-PR list hit the ${PR_LIST_LIMIT} cap since ${since}; older PRs unexamined)")
  elif [[ "$drift" != "inconclusive" && "$drift" -gt 0 ]]; then
    reasons+=("staleness drift = ${drift} (merged PRs touched referenced artifacts since ${since})")
  fi

  if (( ${#reasons[@]} > 0 )); then
    echo "COMPACT_MODE: disqualified (${reasons[0]})"
    local i
    for (( i = 1; i < ${#reasons[@]}; i++ )); do
      echo "  also: ${reasons[$i]}"
    done
    return 0
  fi

  if [[ "$drift" == "inconclusive" ]]; then
    echo "COMPACT_MODE: eligible (staleness inconclusive; falls back to entry criteria)"
  else
    echo "COMPACT_MODE: eligible"
  fi
}

# fetch_issue prints the issue JSON (title, body, createdAt) or fails loudly.
fetch_issue() {
  local repo="$1" issue="$2"
  local -a args=(issue view "$issue" --json "title,body,createdAt")
  if [[ -n "$repo" ]]; then
    args+=(--repo "$repo")
  fi
  if ! gh "${args[@]}"; then
    log_error "failed to fetch issue #${issue} via gh."
    return 1
  fi
}

# count_drift prints the number of merged PRs since $since whose changed files
# intersect any classified artifact. Artifacts are passed as "<kind>\t<value>"
# lines on stdin. When the PR list hits the fetch cap and no match was found, it
# prints "capped" so the caller disqualifies rather than emitting a possibly
# false "eligible" verdict from an undercounted window.
count_drift() {
  local repo="$1" since="$2"
  local -a classified=()
  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    classified+=("$line")
  done

  local -a args=(pr list --state merged --search "merged:>=${since}" --json "number,files" --limit "$PR_LIST_LIMIT")
  if [[ -n "$repo" ]]; then
    args+=(--repo "$repo")
  fi

  local prs_json
  if ! prs_json="$(gh "${args[@]}")"; then
    log_error "failed to list merged PRs via gh."
    return 1
  fi

  local pr_count capped=false
  pr_count="$(jq 'length' <<< "$prs_json")"
  if (( pr_count >= PR_LIST_LIMIT )); then
    capped=true
    log_warn "merged-PR list hit the ${PR_LIST_LIMIT} cap; older merged PRs were not examined. Reporting drift as 'capped' (disqualifying) rather than risk a false 'eligible'."
  fi

  local flat
  flat="$(jq -r '.[] | .number as $n | (.files[]?.path | "\($n)\t\(.)")' <<< "$prs_json")"

  local -a matched_prs=()
  local num file entry kind value
  while IFS=$'\t' read -r num file; do
    [[ -z "$num" ]] && continue
    for entry in "${classified[@]}"; do
      kind="${entry%%$'\t'*}"
      value="${entry#*$'\t'}"
      if file_matches_artifact "$file" "$kind" "$value"; then
        matched_prs+=("$num")
        break
      fi
    done
  done <<< "$flat"

  if (( ${#matched_prs[@]} == 0 )); then
    if [[ "$capped" == true ]]; then
      echo "capped"
      return
    fi
    echo 0
    return
  fi
  printf '%s\n' "${matched_prs[@]}" | sort -u | wc -l | tr -d ' '
}

# Globals populated by parse_args.
ARG_REPO=""
ARG_SINCE=""
ARG_ISSUE=""
ARG_HELP=""

# parse_args reads the command line into the ARG_* globals using getopts, with a
# '-:' arm for long options. Options must precede the positional <issue-number>.
# Returns 0 on success or when help was requested (ARG_HELP set), and non-zero on
# a usage error.
parse_args() {
  ARG_REPO=""
  ARG_SINCE=""
  ARG_ISSUE=""
  ARG_HELP=""

  local argc=$#
  local opt next
  while getopts ":r:s:h-:" opt; do
    case "${opt}" in
      r) ARG_REPO="${OPTARG}" ;;
      s) ARG_SINCE="${OPTARG}" ;;
      h) ARG_HELP="1"; usage; return 0 ;;
      -)
        case "${OPTARG}" in
          repo) next="$(long_optarg repo "${argc}" "${OPTIND}" "${!OPTIND-}")" || return 1
                OPTIND=$(( OPTIND + 1 )); ARG_REPO="${next}" ;;
          repo=*) ARG_REPO="${OPTARG#*=}" ;;
          since) next="$(long_optarg since "${argc}" "${OPTIND}" "${!OPTIND-}")" || return 1
                 OPTIND=$(( OPTIND + 1 )); ARG_SINCE="${next}" ;;
          since=*) ARG_SINCE="${OPTARG#*=}" ;;
          help) ARG_HELP="1"; usage; return 0 ;;
          *) log_error "Unknown option: --${OPTARG}"; usage >&2; return 1 ;;
        esac ;;
      :) log_error "Option -${OPTARG} requires a value."; return 1 ;;
      *) log_error "Unknown option: -${OPTARG}"; usage >&2; return 1 ;;
    esac
  done
  shift $(( OPTIND - 1 ))

  if [[ $# -gt 0 ]]; then
    ARG_ISSUE="$1"
    shift
  fi
  if [[ $# -gt 0 ]]; then
    log_error "Unexpected extra argument: $1"
    return 1
  fi

  if [[ -z "$ARG_ISSUE" || ! "$ARG_ISSUE" =~ ^[0-9]+$ ]]; then
    log_error "A numeric <issue-number> is required."
    usage >&2
    return 1
  fi
}

# print_report emits the human-readable eligibility report. All inputs are
# passed positionally so the function is pure and unit-testable.
# Args: issue age_days since artifacts drift verbs fields advisory
print_report() {
  local issue="$1" age_days="$2" since="$3" artifacts="$4" drift="$5"
  local verbs="$6" fields="$7" advisory="$8"
  local a verbs_disp fields_disp

  echo "issue: #${issue}"
  echo "age_days: ${age_days}"
  echo "window_start: ${since}"
  echo "referenced_artifacts:"
  if [[ -n "$artifacts" ]]; then
    while IFS= read -r a; do
      [[ -z "$a" ]] && continue
      echo "  - ${a}"
    done <<< "$artifacts"
  else
    echo "  (none parsed)"
  fi
  verbs_disp="$(join_commas <<< "$verbs")"
  fields_disp="$(join_commas <<< "$fields")"
  echo "drift: ${drift}"
  echo "risk_class_signal_a_verbs: ${verbs_disp:-none}"
  echo "risk_class_signal_c_fields: ${fields_disp:-none}"
  if [[ -n "$advisory" ]]; then
    echo "RISK_CLASS_ADVISORY: signal (b) possible (${advisory}) - confirm manually"
  fi
}

main() {
  parse_args "$@" || return $?
  [[ -n "$ARG_HELP" ]] && return 0

  local repo="$ARG_REPO"
  local since_override="$ARG_SINCE"
  local issue="$ARG_ISSUE"

  local issue_json title body created_at
  issue_json="$(fetch_issue "$repo" "$issue")" || return 1
  title="$(jq -r '.title // ""' <<< "$issue_json")"
  body="$(jq -r '.body // ""' <<< "$issue_json")"
  created_at="$(jq -r '.createdAt // ""' <<< "$issue_json")"

  local text="${title}"$'\n'"${body}"

  local since
  if [[ -n "$since_override" ]]; then
    since="$(normalize_date "$since_override")"
  else
    since="$(normalize_date "$created_at")"
  fi

  local age_days="unknown"
  if [[ -n "$created_at" ]]; then
    local created_epoch now_epoch
    if created_epoch="$(date -j -f '%Y-%m-%dT%H:%M:%SZ' "$created_at" '+%s' 2> /dev/null)" \
      || created_epoch="$(date -d "$created_at" '+%s' 2> /dev/null)"; then
      now_epoch="$(date '+%s')"
      age_days="$(( (now_epoch - created_epoch) / 86400 ))"
    fi
  fi

  local artifacts
  artifacts="$(parse_artifacts <<< "$text")"

  local verbs fields advisory
  verbs="$(risk_class_verbs <<< "$title")"
  fields="$(risk_class_fields <<< "$text")"
  advisory="$(risk_class_advisory <<< "$text")"

  local classified_lines=""
  if [[ -n "$artifacts" ]]; then
    while IFS= read -r a; do
      [[ -z "$a" ]] && continue
      classified_lines+="$(classify_artifact "$a")"$'\n'
    done <<< "$artifacts"
  fi

  local drift="inconclusive"
  if [[ -n "$artifacts" ]]; then
    drift="$(count_drift "$repo" "$since" <<< "$classified_lines")" || return 1
  fi

  print_report "$issue" "$age_days" "$since" "$artifacts" "$drift" "$verbs" "$fields" "$advisory"

  format_verdict "$verbs" "$fields" "$drift" "$since"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
