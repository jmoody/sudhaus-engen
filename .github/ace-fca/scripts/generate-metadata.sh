#!/usr/bin/env bash
set -euo pipefail

# Parse command-line arguments
AGENT_LLM_ARG=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --agent-llm)
      if [[ $# -lt 2 ]] || [[ -z "${2:-}" ]] || [[ "$2" == --* ]]; then
        echo "Error: --agent-llm requires a value" >&2
        exit 1
      fi
      AGENT_LLM_ARG="$2"
      shift 2
      ;;
    --agent-llm=*)
      AGENT_LLM_ARG="${1#*=}"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Determine LLM model: CLI arg > env var > default
AGENT_LLM_MODEL="${AGENT_LLM_ARG:-${AGENT_LLM:-unknown}}"

# Check for git availability
if ! command -v git &>/dev/null; then
  echo "Error: git is not installed or not in PATH" >&2
  exit 1
fi

# Determine git info from the invoking context
# When called from a symlinked directory (e.g., .github/ace-fca -> copilot/ace-fca/glb),
# we need to find the git repo that contains the symlink, not the symlink target
find_git_root() {
  local logical_cwd
  logical_cwd="$(pwd -L)"
  local physical_cwd
  physical_cwd="$(pwd -P)"
  
  # If logical and physical paths differ, we're in a symlinked directory
  # Walk up the logical path to find the git repo by looking for .git directory only
  if [[ "$logical_cwd" != "$physical_cwd" ]]; then
    local dir="$logical_cwd"
    while [[ "$dir" != "/" ]]; do
      if [[ -d "$dir/.git" ]]; then
        echo "$dir"
        return 0
      fi
      dir="$(dirname "$dir")"
    done
  fi
  
  # Fall back to standard git detection
  git rev-parse --show-toplevel 2>/dev/null
}

# Collect metadata
DATETIME_TZ=$(date '+%Y-%m-%d %H:%M:%S %Z')
FILENAME_TS=$(date '+%Y-%m-%d_%H-%M-%S')

REPO_ROOT=$(find_git_root)
if [[ -n "$REPO_ROOT" ]] && [[ -d "$REPO_ROOT/.git" ]]; then
  REPO_NAME=$(basename "$REPO_ROOT")
  GIT_BRANCH=$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  GIT_COMMIT=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo "")
else
  REPO_ROOT=""
  REPO_NAME=""
  GIT_BRANCH=""
  GIT_COMMIT=""
fi

# Print similar to the individual command outputs
echo "Current Date/Time (TZ): $DATETIME_TZ"
[ -n "$GIT_COMMIT" ] && echo "Current Git Commit Hash: $GIT_COMMIT"
[ -n "$GIT_BRANCH" ] && echo "Current Branch Name: $GIT_BRANCH"
[ -n "$REPO_NAME" ] && echo "Repository Name: $REPO_NAME"
echo "Timestamp For Filename: $FILENAME_TS"
echo "Agent LLM Model: $AGENT_LLM_MODEL"
