---
agent: 'agent'
description: Adversarial code review prompt.
---

# Copilot code review prompt

Review these code changes for issues.

DO NOT MODIFY ANY FILES except the review report. Only provide feedback and suggestions.

## Finding changes to review

Use git to find the files changed on this branch compared to main:

```bash
git diff --name-only $(git merge-base main HEAD)...HEAD
```

Only review files returned by this command. Do not review files that are not in this list.

IMPORTANT: Only review committed changes.

DO NOT review:
- Staged changes (files in the index)
- Unstaged changes (modified files not yet staged)
- Untracked files

## Coding standards

**CRITICAL**: Before reviewing any code, use `read_file` to read each of these instruction files in full:

- .github/copilot-instructions.md (general project guidelines)
- .github/instructions/go.instructions.md (for .go files)
- .github/instructions/bash-scripting.instructions.md (for .sh files)
- .github/instructions/markdown.instructions.md (for .md files)

Read all instruction files FULLY without limit/offset parameters. Do NOT skip this step or rely on summaries. Apply the standards from these files when reviewing changed code.

## Focus areas

This check list accretes over time: each cycle, the retrospective adds a generalized check here for every CCR finding the local review missed (recorded under `What the local review missed`), so future reviews catch that class of defect before push.

- Violations of the project's coding standards
- Bugs and logic errors
- Error handling issues
- Security concerns
- Defensive programming: Constructors and factory functions should validate nil/empty inputs. Specifically check for:
  - Nil map misuse that can panic or cause nil pointer dereferences (for example, writes to a nil map, or assuming map values are non-nil after an error)
  - String prefix assumptions without validation (e.g., assuming `github.com/` prefix)
- Configuration consistency: Example configs should work with tests out of the box. Ports, URLs, or service names hardcoded in configuration files must match what scripts and env vars reference.
- Documentation accuracy: Package comments, script usage text, test names, and inline comments must match actual behavior
- Spec-derived constants: when code encodes a list, enum, or constant taken from a research doc, plan, or binding rule, diff it against the source and flag any missing or extra entries (a CCR round once caught the risk-field list omitting `success_probability` and `probability_adjustment_source` from the source research doc).
- Input-scope fidelity: verify the implementation reads exactly the input the binding rule names, no more (a CCR round once caught a title-scoped signal scanning the entire issue body).
- Fail-safe gates on incomplete data: a gating or decision script must never emit its permissive verdict when a data fetch was capped or truncated; propagate the truncation as the conservative verdict instead (a CCR round once caught a fetch-cap path still printing `eligible`).
- Ordered-document integrity: when a numbered step or section is inserted, confirm the subsequent items are renumbered so the sequence stays monotonic.

## Security checks (Go-specific)

For HTTP handlers and API code, verify:

- Error exposure: Errors returned to clients should NOT include raw `err.Error()` which may leak internal details. Use generic messages instead.
- Fail-safe defaults: Boolean conditions controlling access should fail closed (deny by default), not fail open. Example: `isDev := env == "development"` (allowlist) NOT `isDev := env != "production"` (denylist).
- Input validation: All user inputs from requests should be validated before use.

## Go-specific code quality

For Go files, check for:

- `testify/require` in main goroutine, `s.Require().*` in suites - not `s.Equal()` or `assert.*` (see `.github/instructions/go.instructions.md` require vs assert guidelines)
- Nil map indexing, missing nil guards on pointer/interface params, silent success on nil
- Identifiers containing `/` in URL paths without `url.PathEscape`
- Shared mutable state across goroutines (e.g., stateful objects like `ExponentialBackOff` reused across concurrent requests)
- Decorator/wrapper chains where an outer layer can return without calling the inner layer's method - verify side effects (retry counters, circuit breaker state, metrics) still fire correctly (e.g., `BackOff` wrapper returning a cached value without calling `inner.NextBackOff()`, bypassing a `WithMaxRetries` counter inside `inner`)
- Consumed `io.Reader`/`req.Body` read a second time without rebuffering
- Functions returning `nil, nil` for both success and skip (indistinguishable outcomes for callers)
- Dead code beyond what linters catch: trivially used parameters (logged but never influencing logic), test-only production exports, unreachable branches
- Test design: tests should assert on observable outputs (return values, HTTP status codes, response bodies) not implementation details (panics from nil, internal state). Expected values should match the intended contract, not just make the test pass.

## Bash script checks

For shell scripts, check for:

- Working directory assumptions (e.g., `cat .go-version` without resolving script dir first)
- Fragile version parsing (e.g., grepping `go.mod` instead of using `go list -m`)
- Missing `getopts` for argument parsing (see `.github/instructions/bash.instructions.md`)
- `getopts` parsers that never `shift $((OPTIND-1))` and reject leftover positional arguments, so a stray token (e.g. a mistyped base ref) is silently ignored instead of failing (a CCR round once caught this in `changed-files.sh`)
- Hard-coded env var requirements that may not be set in modern toolchains
- Sourcing files (`. script/foo` or `source script/foo`) without checking the file exists first
- Suppressing stderr with `2>/dev/null` on commands whose failure matters (e.g., gating checks where the error reason helps the user)
- `set -e` gotchas: command substitution inside `echo`, `local`, or `readonly` masks the substitution's exit code. The outer command succeeds even if the inner command fails

## Test coverage check

For new code in implementation files:

1. Identify new exported functions, types, and config fields
2. Check that corresponding test files exist and cover the new code
3. Flag any new config fields (especially `required` ones) that lack test coverage
4. For shell scripts, every function implementing a core gate or decision must have unit tests (e.g. `bats`); functions that shell out (e.g. to `gh`) must be covered with a stubbed command across zero/one/many, de-duplication, command-failure, and cap/truncation paths (a CCR round once caught `count_drift`, the staleness gate, having no tests).

## Test coverage verification

For each modified Go package with new or changed code:

1. Run coverage: `go test -coverprofile=tmp/coverage.out ./<package>/...`
2. Check per-function coverage: `go tool cover -func=tmp/coverage.out`
3. Flag any new or modified function below 75% coverage
4. Flag any function at 0% coverage as a critical gap

## Verification requirements

CRITICAL: Before reporting ANY issue, you MUST verify it exists in the actual file.

Git diff output can be misleading due to:
- Long lines wrapping in terminal display (e.g., `2>/dev/null` appearing truncated when the `l` is on the next display line)
- Diff excerpts not showing the complete file
- Display artifacts from terminal width

For each potential issue identified in a diff:

1. Use `read_file` or `grep` to verify the issue exists in the actual file
2. Only report issues that are confirmed in the source file
3. If verification shows the issue doesn't exist, discard it silently

Example verification commands:
```bash
# Verify a typo exists
grep -n "suspected_typo" path/to/file

# Verify something is missing at end of file
tail -10 path/to/file

# Verify a pattern exists
grep -E "pattern_to_check" path/to/file
```

Do NOT report issues based solely on how the diff appears in terminal output.

## Output format

1. First, write all issues to a markdown file at `tmp/copilot-review-{branch-name}.md` where `{branch-name}` is the current git branch name (replace `/` with `-` in the branch name)
   - Example: branch `jmoody/my-feature` → `tmp/copilot-review-jmoody-my-feature.md`
2. The report file should contain:
   - A summary section with total issue count by severity
   - All issues with file paths and line numbers
3. Then present each issue ONE AT A TIME in the chat
4. For each issue, wait for user feedback before proceeding to the next
5. Format each issue as:

```markdown
## Issue N: [Brief title]

**File**: path/to/file:line
**Description**: What the issue is
**Suggestion**: How to fix it
```

After presenting each issue, ask:

> How would you like to proceed?
> 1. Fix it for me
> 2. I'll fix it differently
> 3. More details please
> 4. Show me other options
> 5. Skip to next issue
