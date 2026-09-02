#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat << EOF
Usage: $0 [OPTIONS]

List the files changed on the current branch relative to a base branch,
computed as the committed diff against the merge-base (git diff BASE...HEAD).

OPTIONS:
  -b, --base <ref>     Base branch or ref to compare against (default: main).
  -e, --ext <ext>      Only list files with this extension (e.g. md, go, sh).
                       Repeatable: -e md -e sh lists both. Omit the leading dot.
      --existing       Only list files that still exist in the working tree.
      --no-symlinks    Exclude symlinks (list real files only).
  -h, --help           Show this help message.

Requires: git. Run from within the repository.
EOF
}

log_error() {
  echo "[ERROR] $*" >&2
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

matches_ext() {
  local file="$1"
  shift
  local ext
  for ext in "$@"; do
    if [[ "${file}" == *".${ext}" ]]; then
      return 0
    fi
  done
  return 1
}

main() {
  local base="main"
  local exts=()
  local existing=false
  local no_symlinks=false

  local argc=$#
  local opt
  local next
  while getopts ":b:e:h-:" opt; do
    case "${opt}" in
      b) base="${OPTARG}" ;;
      e) exts+=("${OPTARG}") ;;
      h) usage; exit 0 ;;
      -)
        case "${OPTARG}" in
          base) next="$(long_optarg base "${argc}" "${OPTIND}" "${!OPTIND-}")" || return 1
                OPTIND=$(( OPTIND + 1 )); base="${next}" ;;
          base=*) base="${OPTARG#*=}" ;;
          ext) next="$(long_optarg ext "${argc}" "${OPTIND}" "${!OPTIND-}")" || return 1
               OPTIND=$(( OPTIND + 1 )); exts+=("${next}") ;;
          ext=*) exts+=("${OPTARG#*=}") ;;
          existing) existing=true ;;
          no-symlinks) no_symlinks=true ;;
          help) usage; exit 0 ;;
          *) log_error "Unknown option: --${OPTARG}"; return 1 ;;
        esac ;;
      :) log_error "Option -${OPTARG} requires a value."; return 1 ;;
      *) log_error "Invalid option: -${OPTARG}."; return 1 ;;
    esac
  done
  shift $(( OPTIND - 1 ))

  if [[ $# -gt 0 ]]; then
    log_error "Unexpected argument: $1. This command accepts options only."
    usage >&2
    return 1
  fi

  local merge_base
  merge_base="$(git merge-base "${base}" HEAD)"

  local file
  while IFS= read -r file; do
    [[ -z "${file}" ]] && continue
    if (( ${#exts[@]} > 0 )) && ! matches_ext "${file}" "${exts[@]}"; then
      continue
    fi
    if [[ "${existing}" == true && ! -e "${file}" ]]; then
      continue
    fi
    if [[ "${no_symlinks}" == true && -L "${file}" ]]; then
      continue
    fi
    printf '%s\n' "${file}"
  done < <(git diff --name-only "${merge_base}...HEAD")
}

main "$@"
