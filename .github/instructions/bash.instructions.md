---
applyTo: "script/**,**/*.sh"
---

# Bash scripting guide instructions

This file is the single source of truth for all Bash scripting standards in this project. All other files should reference this file rather than duplicating these rules.

## Script initialization

- Use `#!/usr/bin/env bash` for maximum portability
- Set `set -euo pipefail` at the top of every script for safer execution:
  - `-e`: Exit on any command failure
  - `-u`: Exit on undefined variable usage
  - `-o pipefail`: Exit on any command in a pipeline failing

```bash
#!/usr/bin/env bash

set -euo pipefail
```

## Function usage

- Use functions for all reusable code blocks
- Define functions before they are used
- Use local variables within functions to avoid global scope pollution
- Include usage/help function for all scripts that accept arguments

```bash
usage() {
  cat << EOF
Usage: $0 [OPTIONS]

Description of what the script does.

OPTIONS:
  -h, --help     Show this help message
  -v, --verbose  Enable verbose output

EOF
}

main() {
  local verbose=false

  while getopts "hv-:" opt; do
    case $opt in
      h) usage; exit 0 ;;
      v) verbose=true ;;
      -) case $OPTARG in
           help) usage; exit 0 ;;
           verbose) verbose=true ;;
           *) echo "Unknown option: --$OPTARG" >&2; exit 1 ;;
         esac ;;
      *) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    esac
  done
}

main "$@"
```

## Command-line option parsing

- Use `getopts` for parsing command-line options
- Support both short (`-h`) and long (`--help`) options
- Provide meaningful error messages for invalid options
- Always include a help option

## Variable handling

- Always quote variables to prevent word splitting and globbing: `"${VAR}"`
- Use `"${VAR:-default}"` for variables with default values
- Use `"${VAR:?error message}"` for required variables
- Use `readonly` for constants (but declare and assign separately - see below)
- Prefer `local` variables in functions

### Declare and assign separately (SC2155)

When using `readonly` or `local` with command substitution, **always declare and assign on separate lines**. This ensures the command's exit code is not masked.

```bash
# Bad: Masks return value - if dirname fails, readonly still returns 0
readonly SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Good: Exit code is preserved, script will fail if command fails
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
readonly SCRIPT_DIR
```

This matters because with `set -e`, a failing command substitution won't cause the script to exit if it's combined with `readonly` or `local`.

```bash
# Good: Proper variable quoting and defaults
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
readonly SCRIPT_DIR
PROJECT_DIR="$(realpath "${SCRIPT_DIR}/..")"
readonly PROJECT_DIR
PORT="${PORT:-9010}"
SERVER_URL="${SERVER_URL:-"http://localhost:${PORT}"}"

function process_file() {
  local file="$1"
  local output_dir="${2:-/tmp}"

  if [[ ! -f "$file" ]]; then
    echo "Error: File '$file' does not exist" >&2
    return 1
  fi

  cp "$file" "$output_dir"
}
```

## Command substitution and execution

- Use `"$(command)"` for command substitution (preferred over backticks)
- Use `[[ ... ]]` for conditional expressions (preferred over `[ ... ]`)
- Use proper exit codes (0 for success, non-zero for failure)

```bash
# Good: Modern bash patterns
if [[ "$(git status --porcelain)" ]]; then
  echo "Working directory is dirty"
  exit 1
fi

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
readonly CURRENT_BRANCH
```

## String manipulation (SC2001)

Prefer bash built-in string manipulation over external tools like `sed` for simple substitutions. This is faster and avoids spawning subprocesses.

```bash
# Bad: Using sed for simple substitution (SC2001)
echo "${variable}" | sed 's/foo/bar/'

# Good: Use bash parameter expansion
echo "${variable//foo/bar}"

# Bad: Using sed to add prefix to each line
echo "${lines}" | sed 's/^/  /'

# Good: Use a while loop for line-by-line processing
while IFS= read -r line; do
  echo "  ${line}"
done <<< "${lines}"
```

Common bash string operations:
- `${var#pattern}` - Remove shortest match from beginning
- `${var##pattern}` - Remove longest match from beginning
- `${var%pattern}` - Remove shortest match from end
- `${var%%pattern}` - Remove longest match from end
- `${var/pattern/replacement}` - Replace first match
- `${var//pattern/replacement}` - Replace all matches

## File sourcing and portability

- Use `. <file>` instead of `source <file>` for POSIX portability
- Check file existence before sourcing

```bash
# Good: Portable file sourcing
if [[ -f ".env" ]]; then
  . .env
fi
```

## Error handling

- Use explicit error checking for critical operations
- Provide meaningful error messages to stderr
- Use appropriate exit codes
- Clean up temporary files on exit

```bash
# Good: Error handling with cleanup
cleanup() {
  if [[ -n "${TEMP_DIR:-}" ]]; then
    rm -rf "$TEMP_DIR"
  fi
}

trap cleanup EXIT

TEMP_DIR="$(mktemp -d)"
readonly TEMP_DIR

if ! docker build -t "$IMAGE_TAG" .; then
  echo "Error: Failed to build Docker image" >&2
  exit 1
fi
```

## Code style and formatting

- Indent with 2 spaces (no tabs)
- Do not use Unicode characters or emoji in scripts; use plain ASCII text only
- Do not add unnecessary comments; code should be self-explanatory
- Do not add a comment when a log message explains what is happening
- Use meaningful variable and function names

## Output and logging

- Send errors to stderr using `>&2`
- Use `echo` for simple output, `printf` for formatted output
- Consider using a consistent logging format for complex scripts

```bash
# Good: Proper output handling
log_info() {
  echo "[INFO] $*"
}

log_error() {
  echo "[ERROR] $*" >&2
}

log_info "Starting deployment process"
if ! deploy_to_staging; then
  log_error "Deployment failed"
  exit 1
fi
```

## Integration with project workflow

### Quality assurance
- Test scripts in different environments
- Use shellcheck for static analysis when available
- Include scripts in CI/CD validation pipeline
