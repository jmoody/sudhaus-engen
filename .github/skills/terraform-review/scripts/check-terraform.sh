#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat << EOF
Usage: $0 [OPTIONS] [ROOT...]

Statically review Engen Brews's Terraform against the contract in
.github/instructions/terraform.instructions.md. Runs credential-free: it never
calls Azure, never runs terraform plan/apply, and needs no backend access.

A ROOT is any directory containing at least one *.tf file. With no ROOT
argument, every root under terraform/ is checked. Each root is reported with a
per-root OK line unless --quiet is given; the script exits non-zero if any root
has a finding.

Checks performed per root:
  - terraform fmt -check (skipped with a NOTE when terraform is not installed).
  - A versions.tf file is absent (this repo uses terraform.tf).
  - No subscription id is committed as a literal (must be var.subscription_id).
  - The terraform {} block and provider blocks live in terraform.tf, not main.tf.
  - Every variable block has a description.
  - variable "location" has no default.
  - Every taggable resource (heuristically, any azurerm_* resource that sets a
    location) declares tags, and every tags block carries service = "engen-brews" and an
    environment key (a tags value that references common_tags is accepted when a
    locals block defines common_tags with both keys).

The tag and block checks are line-oriented heuristics, not a full HCL parser;
they assume the simple, one-resource-per-block style used in this repo.

OPTIONS:
  -q, --quiet     Only report findings, not the per-root OK line.
  -h, --help      Show this help message.
EOF
}

log_fail() {
  echo "  FAIL ${1}: ${2}" >&2
}

log_note() {
  echo "  NOTE ${1}: ${2}"
}

find_roots() {
  local base="$1"
  find "${base}" -type f -name '*.tf' -not -path '*/.terraform/*' \
    -exec dirname {} \; | sort -u
}

check_fmt() {
  local root="$1"
  if ! command -v terraform > /dev/null 2>&1; then
    log_note "${root}" "terraform not installed; skipping fmt check"
    return 0
  fi
  local out status
  out="$(terraform fmt -check -list=true "${root}" 2>&1)" && status=0 || status=$?
  if [[ "${status}" -ne 0 ]]; then
    if [[ -n "${out}" ]]; then
      while IFS= read -r line; do
        [[ -n "${line}" ]] && log_fail "${root}" "terraform fmt: ${line}"
      done <<< "${out}"
    else
      log_fail "${root}" "terraform fmt failed with status ${status}"
    fi
    return 1
  fi
  return 0
}

check_versions_file() {
  local root="$1"
  if [[ -f "${root}/versions.tf" ]]; then
    log_fail "${root}" "versions.tf present; this repo puts the terraform {} block in terraform.tf"
    return 1
  fi
  return 0
}

check_committed_subscription() {
  local root="$1"
  local hits
  hits="$(grep -rEn \
    'subscription_id[[:space:]]*=[[:space:]]*"[0-9a-fA-F-]{8,}"' \
    "${root}"/*.tf 2> /dev/null || true)"
  if [[ -n "${hits}" ]]; then
    while IFS= read -r hit; do
      log_fail "${root}" "subscription id committed as a literal (use var.subscription_id): ${hit}"
    done <<< "${hits}"
    return 1
  fi
  return 0
}

common_tags_ok() {
  local root="$1"
  local expected="$2"
  local block
  block="$(
    awk '
      {
        line = $0
        if (cap == 0 && line ~ /common_tags[[:space:]]*=[[:space:]]*{/) {
          cap = 1
          buf = ""
          depth = 0
        }
        if (cap) {
          buf = buf "\n" line
          t = line
          o = gsub(/{/, "{", t)
          t = line
          c = gsub(/}/, "}", t)
          depth += o - c
          if (depth <= 0) {
            print buf
            cap = 0
          }
        }
      }
    ' "${root}"/*.tf 2> /dev/null
  )"

  if [[ -z "${block}" ]]; then
    echo 0
    return 0
  fi
  if ! grep -qE 'service[[:space:]]*=[[:space:]]*"engen-brews"' <<< "${block}"; then
    echo 0
    return 0
  fi

  local env_line env_val
  env_line="$(grep -oE 'environment[[:space:]]*=[[:space:]]*"[^"]*"' <<< "${block}" | head -1)"
  if [[ -z "${env_line}" ]]; then
    echo 0
    return 0
  fi
  env_val="${env_line#*\"}"
  env_val="${env_val%\"*}"

  if [[ -n "${expected}" ]]; then
    [[ "${env_val}" == "${expected}" ]] && echo 1 || echo 0
    return 0
  fi
  case "${env_val}" in
    production | staging | lab) echo 1 ;;
    *) echo 0 ;;
  esac
}

check_blocks() {
  local root="$1"
  local common_ok="$2"
  local expected_env="$3"
  local status=0
  local findings
  findings="$(
    awk -v common_ok="${common_ok}" -v expected_env="${expected_env}" '
      function env_value(b,   s) {
        if (match(b, /environment[[:space:]]*=[[:space:]]*"[^"]*"/)) {
          s = substr(b, RSTART, RLENGTH)
          sub(/^[^"]*"/, "", s)
          sub(/".*/, "", s)
          return s
        }
        return ""
      }
      function process(header, body, file,   name, rtype, ev) {
        if (header ~ /^[[:space:]]*terraform[[:space:]]/) {
          if (file !~ /terraform\.tf$/)
            print file ": terraform {} block must live in terraform.tf"
          return
        }
        if (header ~ /^[[:space:]]*provider[[:space:]]/) {
          if (file !~ /terraform\.tf$/)
            print file ": provider block must live in terraform.tf"
          return
        }
        if (header ~ /^[[:space:]]*variable[[:space:]]/) {
          name = header
          sub(/^[^"]*"/, "", name)
          sub(/".*/, "", name)
          if (body !~ /\n[[:space:]]*description[[:space:]]*=/)
            print file ": variable \"" name "\" has no description"
          if ((name == "location" || name == "subscription_id") \
              && body ~ /\n[[:space:]]*default[[:space:]]*=/)
            print file ": variable \"" name "\" must not declare a default"
          return
        }
        if (header ~ /^[[:space:]]*resource[[:space:]]+"azurerm_/) {
          rtype = header
          sub(/^[^"]*"/, "", rtype)
          sub(/".*/, "", rtype)
          if (body !~ /\n[[:space:]]*location[[:space:]]*=/)
            return
          if (body !~ /\n[[:space:]]*tags[[:space:]]*=/) {
            print file ": " rtype " sets a location but declares no tags"
            return
          }
          if (body ~ /common_tags/) {
            if (common_ok != "1")
              print file ": " rtype " uses common_tags but its locals block lacks service = \"engen-brews\" or a valid environment"
            return
          }
          if (body !~ /service[[:space:]]*=[[:space:]]*"engen-brews"/)
            print file ": " rtype " tags must include service = \"engen-brews\""
          ev = env_value(body)
          if (ev == "")
            print file ": " rtype " tags must include an environment key"
          else if (expected_env != "" && ev != expected_env)
            print file ": " rtype " environment tag is \"" ev "\" but this root requires \"" expected_env "\""
          else if (expected_env == "" && ev != "production" && ev != "staging" && ev != "lab")
            print file ": " rtype " environment tag \"" ev "\" is not one of production, staging, lab"
          return
        }
      }
      {
        raw = $0
        if (depth == 0 && raw ~ /^[[:space:]]*(resource|data|variable|output|module|provider|locals|terraform)[[:space:]]/) {
          inblock = 1
          header = raw
          body = ""
        }
        if (inblock) body = body "\n" raw
        tmp = raw
        opens = gsub(/{/, "{", tmp)
        tmp = raw
        closes = gsub(/}/, "}", tmp)
        depth += opens - closes
        if (depth < 0) depth = 0
        if (inblock && depth == 0) {
          process(header, body, FILENAME)
          inblock = 0
        }
      }
    ' "${root}"/*.tf 2> /dev/null
  )"
  if [[ -n "${findings}" ]]; then
    while IFS= read -r finding; do
      log_fail "${root}" "${finding}"
      status=1
    done <<< "${findings}"
  fi
  return "${status}"
}

review_root() {
  local root="$1"
  local quiet="$2"
  local status=0
  local common_ok expected_env

  expected_env=""
  case "${root}" in
    */prod | */prod/* | */production | */production/*) expected_env="production" ;;
    */staging | */staging/*) expected_env="staging" ;;
    */lab | */lab/*) expected_env="lab" ;;
  esac

  check_fmt "${root}" || status=1
  check_versions_file "${root}" || status=1
  check_committed_subscription "${root}" || status=1
  common_ok="$(common_tags_ok "${root}" "${expected_env}")"
  check_blocks "${root}" "${common_ok}" "${expected_env}" || status=1

  if [[ "${status}" -eq 0 && "${quiet}" == false ]]; then
    echo "OK   ${root}"
  fi
  return "${status}"
}

main() {
  local quiet=false

  while getopts "qh-:" opt; do
    case "${opt}" in
      q) quiet=true ;;
      h)
        usage
        exit 0
        ;;
      -)
        case "${OPTARG}" in
          quiet) quiet=true ;;
          help)
            usage
            exit 0
            ;;
          *)
            echo "Unknown option: --${OPTARG}" >&2
            exit 1
            ;;
        esac
        ;;
      *)
        usage >&2
        exit 1
        ;;
    esac
  done
  shift $((OPTIND - 1))

  local roots=()
  if [[ $# -gt 0 ]]; then
    roots=("$@")
  else
    if [[ ! -d terraform ]]; then
      echo "No terraform/ directory found; run from the repository root." >&2
      exit 1
    fi
    while IFS= read -r root; do
      roots+=("${root}")
    done < <(find_roots terraform)
  fi

  if [[ "${#roots[@]}" -eq 0 ]]; then
    echo "No Terraform roots (directories with *.tf files) found." >&2
    exit 1
  fi

  local exit_status=0
  local root
  for root in "${roots[@]}"; do
    review_root "${root}" "${quiet}" || exit_status=1
  done

  return "${exit_status}"
}

main "$@"
