#!/usr/bin/env bash

set -euo pipefail

# Determine ACE_FCA_DIR based on how the script was invoked
# If invoked via symlink (e.g., ./scripts/archive-documents.sh where scripts -> ../.common/scripts),
# we need to use the invoking directory context, not the physical script location
resolve_ace_fca_dir() {
  local invoked_path="$1"
  local invoked_dir
  invoked_dir="$(dirname "$invoked_path")"

  # Get the logical directory (preserves symlink path)
  local logical_dir
  logical_dir="$(cd "$invoked_dir" && pwd -L)"

  # Get the physical directory (resolves symlinks)
  local physical_dir
  physical_dir="$(cd "$invoked_dir" && pwd -P)"

  # If logical and physical differ, we were called via symlink.
  # Walk up the LOGICAL path to find the correct repo's ace-fca directory.
  # The realpath call here just normalizes the result (removes .., etc.) -
  # it does NOT defeat the symlink detection because we've already determined
  # which directory tree to use by comparing logical vs physical paths.
  if [[ "$logical_dir" != "$physical_dir" ]]; then
    realpath "$(cd "$invoked_dir/.." && pwd -L)"
  else
    realpath "$invoked_dir/.."
  fi
}

ACE_FCA_DIR="$(resolve_ace_fca_dir "$0")"
readonly ACE_FCA_DIR
readonly TMP_DIR="${ACE_FCA_DIR}/tmp"
readonly DEFAULT_KEEP_N=10

extract_number() {
  local filename="$1"
  local number_part="${filename%%-*}"
  echo "$((10#${number_part}))"
}

is_scaffold_retro() {
  local file="$1"

  if grep -q "will be completed after implementation" "$file" 2>/dev/null; then
    return 0
  fi

  return 1
}

delete_scaffold_retros() {
  local category="$1"
  local dir="$2"
  local preview_mode="$3"

  if [[ "$category" != "retros" ]]; then
    return 0
  fi

  local deleted_count=0
  local file

  while IFS= read -r file; do
    if is_scaffold_retro "$file"; then
      ((deleted_count++)) || true

      if [[ "$preview_mode" == "false" ]]; then
        rm "$file"
      fi
    fi
  done < <(find "$dir" -maxdepth 1 -name "[0-9][0-9][0-9][0-9]-*.md" -type f)

  if [[ "$deleted_count" -gt 0 ]]; then
    if [[ "$preview_mode" == "true" ]]; then
      echo "PREVIEW MODE: $deleted_count scaffold retro(s) would be deleted"
    else
      echo "Deleted $deleted_count scaffold retro(s)"
    fi
  fi
}

list_category_files() {
  local category="$1"
  local base_dir="${2:-.github/ace-fca}"
  local tmp_dir="${3:-$TMP_DIR}"

  local category_dir="${base_dir}/${category}"
  local output_file="${tmp_dir}/files-${category}.txt"

  if [[ ! -d "$category_dir" ]]; then
    touch "$output_file"
    return 0
  fi

  find "$category_dir" -maxdepth 1 -name "*.md" -type f | sort > "$output_file"
}

find_top_n_numbers() {
  local category="$1"
  local tmp_dir="${2:-$TMP_DIR}"
  local n="${KEEP_N:-$DEFAULT_KEEP_N}"

  local input_file="${tmp_dir}/files-${category}.txt"
  local output_file="${tmp_dir}/top-n-${category}.txt"

  if [[ ! -f "$input_file" ]]; then
    touch "$output_file"
    return 0
  fi

  while IFS= read -r filepath; do
    local filename
    filename=$(basename "$filepath")
    extract_number "$filename"
  done < "$input_file" | sort -rn | head -"$n" > "$output_file"
}

should_archive_file() {
  local file="$1"
  local number="$2"
  local category="$3"
  local tmp_dir="${4:-$TMP_DIR}"

  local top_n_file="${tmp_dir}/top-n-${category}.txt"

  if grep -qx "$number" "$top_n_file" 2>/dev/null; then
    return 1
  fi

  return 0
}

identify_archive_candidates() {
  local category="$1"
  local base_dir="${2:-.github/ace-fca}"
  local tmp_dir="${3:-$TMP_DIR}"

  mkdir -p "$tmp_dir"

  list_category_files "$category" "$base_dir" "$tmp_dir"
  find_top_n_numbers "$category" "$tmp_dir"

  local input_file="${tmp_dir}/files-${category}.txt"
  local output_file="${tmp_dir}/archive-candidates-${category}.txt"

  : > "$output_file"

  while IFS= read -r filepath; do
    if [[ ! -f "$filepath" ]]; then
      continue
    fi

    local filename
    filename=$(basename "$filepath")
    local number
    number=$(extract_number "$filename")

    if should_archive_file "$filepath" "$number" "$category" "$tmp_dir"; then
      echo "$filepath" >> "$output_file"
    fi
  done < "$input_file"
}

add_archived_date() {
  local file="$1"
  local archive_date
  archive_date=$(date +%Y-%m-%d)

  if ! grep -q "^---" "$file"; then
    return 1
  fi

  local temp_file="${file}.tmp"
  local in_frontmatter=false
  local added=false

  while IFS= read -r line; do
    if [[ "$line" == "---" ]]; then
      if [[ "$in_frontmatter" == false ]]; then
        in_frontmatter=true
        echo "$line"
      else
        if [[ "$added" == false ]]; then
          echo "archived_date: ${archive_date}"
          added=true
        fi
        echo "$line"
        in_frontmatter=false
      fi
    else
      echo "$line"
    fi
  done < "$file" > "$temp_file"

  mv "$temp_file" "$file"
}

move_to_archive() {
  local file="$1"
  local category="$2"
  local base_dir="${3:-.github/ace-fca}"
  local failures_file="${4:-}"

  local archive_dir="${base_dir}/archives/${category}"

  if ! mkdir -p "$archive_dir" 2>/dev/null; then
    echo "Error: Failed to create archive directory: $archive_dir" >&2
    if [[ -n "$failures_file" ]]; then
      echo "$file" >> "$failures_file"
    fi
    return 1
  fi

  local filename
  filename=$(basename "$file")
  local dest="${archive_dir}/${filename}"

  if ! mv "$file" "$dest" 2>/dev/null; then
    echo "Error: Failed to move $file to $dest" >&2
    if [[ -n "$failures_file" ]]; then
      echo "$file" >> "$failures_file"
    fi
    return 1
  fi

  echo "Archived: $filename -> archives/${category}/"
}

preview_mode() {
  local category="$1"
  local tmp_dir="${2:-$TMP_DIR}"

  local candidates_file="${tmp_dir}/archive-candidates-${category}.txt"

  if [[ ! -f "$candidates_file" ]]; then
    echo "PREVIEW MODE: No candidates for ${category}"
    return 0
  fi

  local count
  count=$(wc -l < "$candidates_file" | tr -d ' ')

  if [[ "$count" -eq 0 ]]; then
    echo "PREVIEW MODE: No candidates for ${category}"
    return 0
  fi

  echo "PREVIEW MODE: ${count} file(s) would be archived from ${category}:"
  while IFS= read -r filepath; do
    local filename
    filename=$(basename "$filepath")
    local number
    number=$(extract_number "$filename")
    echo "  - ${filename} (number: ${number})"
  done < "$candidates_file"
  echo ""
}

execute_mode() {
  local category="$1"
  local base_dir="${2:-.github/ace-fca}"
  local tmp_dir="${3:-$TMP_DIR}"

  local candidates_file="${tmp_dir}/archive-candidates-${category}.txt"
  local failures_file="${tmp_dir}/move-failures.txt"

  if [[ ! -f "$candidates_file" ]]; then
    echo "No candidates for ${category}"
    return 0
  fi

  local count
  count=$(wc -l < "$candidates_file" | tr -d ' ')

  if [[ "$count" -eq 0 ]]; then
    echo "No candidates for ${category}"
    return 0
  fi

  echo "Archiving ${count} file(s) from ${category}..."

  local success_count=0
  local failure_count=0

  while IFS= read -r filepath; do
    if add_archived_date "$filepath"; then
      if move_to_archive "$filepath" "$category" "$base_dir" "$failures_file"; then
        ((success_count++)) || true
      else
        ((failure_count++)) || true
      fi
    else
      echo "Error: Failed to add archived_date to $filepath" >&2
      echo "$filepath" >> "$failures_file"
      ((failure_count++)) || true
    fi
  done < "$candidates_file"

  echo "Archived: ${success_count} file(s), Failed: ${failure_count} file(s)"
  echo ""
}

usage() {
  cat << EOF
Usage: $0 [OPTIONS]

Archive old research, plan, and retrospective documents.

OPTIONS:
  -h, --help       Show this help message
  -e, --execute    Execute archival (default is preview mode)
  -k, --keep-n N   Keep top N documents per category (default: 10)

ENVIRONMENT:
  KEEP_N           Number of documents to keep (overridden by --keep-n)

BEHAVIOR:
  Default mode (no flags): Preview mode - show what would be archived
  --execute: Actually move files to archive directories (non-interactive)

ARCHIVAL RULES:
  Keep: Last N documents by sequential number (highest numbers, default N=10)
  Archive: Everything else to .github/ace-fca/archives/{category}/

EOF
}

main() {
  local execute=false
  local base_dir="$ACE_FCA_DIR"
  local keep_n="${KEEP_N:-$DEFAULT_KEEP_N}"

  while getopts "hek:-:" opt; do
    case $opt in
      h) usage; exit 0 ;;
      e) execute=true ;;
      k) keep_n="$OPTARG" ;;
      -) case $OPTARG in
           help) usage; exit 0 ;;
           execute) execute=true ;;
           keep-n)
             keep_n="${!OPTIND}"
             OPTIND=$((OPTIND + 1))
             ;;
           keep-n=*)
             keep_n="${OPTARG#*=}"
             ;;
           *) echo "Unknown option: --$OPTARG" >&2; usage; exit 1 ;;
         esac ;;
      *) echo "Invalid option: -$OPTARG" >&2; usage; exit 1 ;;
    esac
  done

  if ! [[ "$keep_n" =~ ^[0-9]+$ ]] || [[ "$keep_n" -lt 1 ]]; then
    echo "Error: --keep-n must be a positive integer" >&2
    exit 1
  fi

  export KEEP_N="$keep_n"

  local preview_mode="true"
  if [[ "$execute" == true ]]; then
    preview_mode="false"
  fi

  mkdir -p "$TMP_DIR"

  for category in research plans retros; do
    delete_scaffold_retros "$category" "${base_dir}/${category}" "$preview_mode"
    identify_archive_candidates "$category" "$base_dir" "$TMP_DIR"

    if [[ "$execute" == true ]]; then
      execute_mode "$category" "$base_dir" "$TMP_DIR"
    else
      preview_mode "$category" "$TMP_DIR"
    fi
  done

  local move_failures="${TMP_DIR}/move-failures.txt"
  if [[ -f "$move_failures" ]] && [[ -s "$move_failures" ]]; then
    local count
    count=$(wc -l < "$move_failures" | tr -d ' ')
    echo "Error: ${count} file(s) could not be processed:" >&2
    cat "$move_failures" >&2
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
