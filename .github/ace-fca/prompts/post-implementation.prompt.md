---
agent: 'agent'
description: Post-implementation quality review for ACE-FCA implementations.
---

# Post-implementation review

You just completed implementing a plan. Before declaring victory, review what you built.

Implementation agents optimize for "make the tests pass" and "follow the plan." This creates blind spots:

1. **Plan-induced debt**: The plan may have introduced patterns that work but aren't ideal
2. **Incidental complexity**: Quick fixes during implementation that should be cleaned up
3. **Style drift**: Subtle deviations from project conventions under time pressure

## Scope

**Only review code modified in this implementation.** Use `get_changed_files` (or appropriate base branch) to identify changed files.

Do not review:
- Code that existed before this implementation
- Files not touched by this implementation
- Hypothetical future improvements

## Quality checks

Review each modified file for:

### 1. Technical debt
- Duplicate code (copy-paste from elsewhere in codebase)
- Unused functions or variables introduced
- Tight coupling between components that should be independent
- Semantic dead code the linter misses: regex groups that never capture meaningful data, params trivially consumed (logged or assigned to `_` but never influencing logic), exported env vars nothing reads, unreachable branches guarded by conditions that are always true/false
- Code in production paths that only supports tests: exported fields, methods, or constructors called exclusively from `_test` files
- Dependencies loaded unconditionally even when a feature flag or config disables the feature

### 2. Long functions
- Functions exceeding 50 lines
- Functions with multiple distinct responsibilities
- Functions that should be split for testability

### 3. Leaky abstractions
- Provider-specific types exposed in interfaces
- Implementation details leaking through API boundaries
- Concrete types where interfaces would be appropriate

### 4. Complex logic
- Deeply nested conditionals (>3 levels)
- Unclear control flow
- Missing early returns that would simplify logic

### 5. Style guide violations
- Check against `.github/instructions/*.instructions.md`
- Go: No `Get`/`Set` prefixes, use `any` not `interface{}`, use `testify/require` (see `.github/instructions/go.instructions.md`)
- Bash: functions, error handling, quoting (see `.github/instructions/bash-scripting.instructions.md`)
- Markdown: sentence case headings, minimal bold (see `.github/instructions/markdown.instructions.md`)

### 6. Documentation accuracy
- Comments describing past state ("was", "used to", "changed from")
- Redundant comments restating what code does
- Package comments that don't match package behavior (e.g., "read-only" on a package that writes)
- Usage/help text that doesn't match actual script behavior
- Test names that contradict what the test validates

### 7. Configuration consistency
- Example `.env` files match what tests actually expect
- Hardcoded constants (URLs, env var names) match actual environment values
- Cross-file consistency: ports, URLs, or service names hardcoded in docker-compose files match what scripts and env vars reference

### 8. Adversarial thinking

After completing checks 1-7, assume there ARE issues you missed and look again:
- **Production inputs**: For each string built from external data, list realistic production values. Do they contain characters that could break the construction? (e.g., repository names with `/` in URL paths need `url.PathEscape`, user input in `fmt.Sprintf` format strings)
- **Blast radius of error paths**: For each new `log.Fatal`, `panic`, or `os.Exit`, what happens to the caller? These terminate the process - observability features (metrics, logging, tracing) must never crash the operation they observe. For each `return fmt.Errorf(...)`, does the error message leak internal details that would reach an HTTP client via `http.Error(w, err.Error(), ...)`?
- **Nil and zero-value safety**: For each function accepting a pointer or interface parameter, what happens when the caller passes `nil`? For each struct with pointer fields, does the zero value cause a nil dereference? Check that new code doesn't silently succeed on nil inputs (see go.instructions.md defensive programming)
- **Resource lifecycle**: For each new `http.Response`, file handle, or connection, verify there is a corresponding `defer resp.Body.Close()` or `defer f.Close()`. For each consumed `io.Reader` or `req.Body`, verify it is not read a second time without rebuffering
- **Test isolation and design**: For each modified test file, does any test make real network calls or depend on external services without a mock/stub? Does shared test state (package-level variables, suite fields) leak between test cases? Verify `testify/require` is used instead of `testify/assert` in the main test goroutine (see go.instructions.md require vs assert guidelines). Env vars set in tests must be cleaned up (`t.Setenv` or explicit cleanup). Suite fields must be reset between test methods where mutation occurs. Tests should assert on observable outputs (return values, HTTP status codes, response bodies) not implementation details (panics from nil, internal state). Compare expected values against the intended contract - a passing test with the wrong expected value is worse than a failing one. Don't test language guarantees (JSON round-trip, protobuf zero values, `omitempty` behavior). These are Go/library guarantees, not application logic.
- **Concurrency**: For each new goroutine, how does it exit? For each shared map or slice, is concurrent access protected? For each new `context.Context`, is cancellation propagated correctly?
- **Future callers**: For each new exported function, method, or type, what happens if a future caller misuses the API? Are zero values safe? Do boolean parameters default to the secure/restrictive option (fail closed, not fail open)?
- **Decorator/wrapper composition**: For each chain of wrappers (middleware, backoff decorators, transport layers), trace what happens when the outermost layer short-circuits and never calls the inner layer. Do all inner layers that maintain state (counters, circuit breakers, rate limiters) still update correctly? Write a "persistent failure" test for each wrapper chain: if the overridden behavior fires on every attempt, are retries/resources still bounded?
- **Shell script error paths**: For each `source`/`.` command, what happens if the target file doesn't exist? For each `2>/dev/null`, what errors are being silenced - would the user need to see them to diagnose a failure? For each command substitution inside `echo`, `local`, or `readonly`, does `set -e` still catch failures? (It doesn't - declare and assign separately.)

## Severity classification

- 🔴 **Critical**: Fix before merge. Bugs, security issues, or violations that will cause problems.
- 🟡 **Important**: Fix soon. Technical debt that will compound if left.
- 🟢 **Nice-to-have**: Future improvement. Polish that isn't blocking.

## Process (INTERACTIVE)

Present findings ONE AT A TIME. After each finding, STOP and WAIT for human response.

**Format for each finding**:

```
**Severity**: [🔴 Critical | 🟡 Important | 🟢 Nice-to-have]
**File**: [path/to/file.go:line-range]
**Issue**: [What's wrong]
**Suggested fix**: [How to address it]

Fix now? (yes/no/defer)
```

## Retrospective integration

After all findings are addressed, update the retrospective document under:

**"What the local review missed" → "Local-gate gaps and fixes"**

Add a summary answering: What quality issues appeared during implementation that the plan didn't anticipate, and which local check now guards against each? The checks in this prompt are extended each cycle from the CCR misses recorded under that heading, so the local gate catches more before push.

Example entry:
```markdown
### Local-gate gaps and fixes

- 🟡 Function `processDiscussions` grew to 67 lines during implementation; plan didn't anticipate complexity
- 🟢 Copy-pasted error handling pattern 3 times; should extract helper
- Observation: Plan phases were too large, leading to "just get it working" shortcuts
```

## Goal

Catch quality issues while context is fresh. It's cheaper to fix problems now than to rediscover them in code review or production.

## Test coverage verification

For each modified Go package with new or changed code:

1. Run coverage: `go test -coverprofile=tmp/coverage.out ./<package>/...`
2. Check per-function coverage: `go tool cover -func=tmp/coverage.out`
3. Flag any new or modified function below 75% coverage
4. Flag any function at 0% coverage as a critical gap
