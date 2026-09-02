#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")" && pwd)"
readonly SCRIPT_DIR

usage() {
  cat << EOF
Usage: $0 [OPTIONS] FILE [FILE...]

Apply .github/instructions/markdown.instructions.md formatting to Markdown files:
  - Unwrap hard-wrapped prose and list items into single logical lines.
  - Align every table so pipes line up (alignment markers preserved).

Both transforms are idempotent, so re-running on a compliant file is a no-op.

OPTIONS:
  -c, --check    Do not modify files; exit non-zero if any file is not compliant.
  -v, --verbose  Print the name of each file that changed.
  -h, --help     Show this help message.
EOF
}

format_file() {
  local file="$1"
  LC_ALL=C awk -f "${SCRIPT_DIR}/unwrap-prose.awk" "$file" \
    | LC_ALL=C awk -f "${SCRIPT_DIR}/align-tables.awk"
}

main() {
  local check=false
  local verbose=false

  while getopts "cvh-:" opt; do
    case $opt in
      c) check=true ;;
      v) verbose=true ;;
      h) usage; exit 0 ;;
      -) case $OPTARG in
           check) check=true ;;
           verbose) verbose=true ;;
           help) usage; exit 0 ;;
           *) echo "Unknown option: --$OPTARG" >&2; exit 1 ;;
         esac ;;
      *) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    esac
  done
  shift $((OPTIND - 1))

  if [[ $# -eq 0 ]]; then
    usage >&2
    exit 1
  fi

  local rc=0
  local file formatted
  for file in "$@"; do
    if [[ ! -f "$file" ]]; then
      echo "[ERROR] File '$file' does not exist" >&2
      exit 1
    fi
    formatted="$(format_file "$file")"
    if [[ "$formatted" == "$(cat "$file")" ]]; then
      continue
    fi
    if [[ "$check" == true ]]; then
      echo "[CHECK] not compliant: $file" >&2
      rc=1
    else
      printf '%s\n' "$formatted" > "$file.tmp"
      mv "$file.tmp" "$file"
      if [[ "$verbose" == true ]]; then
        echo "[FIXED] $file"
      fi
    fi
  done

  return "$rc"
}

main "$@"
