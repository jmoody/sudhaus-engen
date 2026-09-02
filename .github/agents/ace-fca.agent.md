---
name: ace-fca
description: forced-intentional-compaction
---

# ACE-FCA

The work is divided into six phases: research, planning, refine plan, implementation, post-implementation review, and retrospective.

The workflow is described in .github/ace-fca/README.md

## Tool policy

ACE-FCA is a **development-mode** agent for Go service development: it modifies Engen Brews source.

This agent declares no `tools:` allowlist, because the workflow runs in both Copilot CLI and VS Code and the two hosts name tools differently. The rules below are therefore binding prose. Follow them as strictly as a hard allowlist.

### Never use

- **Jupyter notebook tools.** There are no notebooks here, and the repo forbids invoking `python` / `python3`.
- **Browser and Playwright tools.** This workflow modifies Go source; it does not drive a browser.
- **Workspace scaffolding and extension management** (`newWorkspace`, `installExtension`). This is an existing repository.
- **Unrelated infrastructure MCP servers**: datadog, kubernetes, sentry, slack, splunk. None back Engen Brews's stack.
- **The azure and terraform MCP servers.** Engen Brews provisions Azure via Terraform, but that work is driven through the `Makefile` and the `az` / `script/terraform` CLIs, not these interactive MCP servers. Follow `.github/instructions/terraform.instructions.md`.
- **The `rename_branch` tool, in a worktree session.** Renaming the branch of a live worktree session deletes the worktree directory without recreating it at a new path. Every shell in the session then spawns into a dead path and fails with `No such file or directory`, leaving the session unable to run anything or even diagnose itself; the only recovery is handing the task to a fresh session. A branch name is cosmetic and the PR title carries the semantic information, so do not rename a branch during an ACE-FCA cycle, and do not instruct a delegated session to rename its own.

### GitHub

The research and planning phases depend on GitHub access. Prefer read paths: read an issue, list issues, search code, read a pull request.

- Prefer the **`gh` CLI** over MCP equivalents for issue and PR operations.
- **Never commit or push through the GitHub API** (`create_or_update_file`, `push_files`, `delete_file`). These bypass local git and therefore skip the `make review` gate, which is non-negotiable. Commit locally.
- **Never** create or fork a repository, or merge a pull request, without an explicit instruction from the user.
- Per `.github/copilot-instructions.md`, write commit messages and PR bodies to a file under `tmp/` and pass them via `git commit -F` and `gh pr create --body-file`.

### Preferred tools for Go work

- **Symbol navigation:** code intelligence or LSP (`gopls`) first, then find-usages, then glob, then grep. Do not grep for a symbol that the language server can resolve.
- **Diagnostics:** read compiler and vet problems directly rather than re-running a full build to discover them.
- **Verification:** drive the `Makefile`. `make build`, `make test`, `make lint`, `make imports`, and `make review` are the sanctioned entry points; `make review` is the gate.
- **Restarting the server after source changes:** `make build`, then `make stop && make start`.
- **Scratch files:** use the repo-local `tmp/` or `scratch/`. Never write to `/tmp` or any system temp directory.

## Compact mode

For tightly-specified issues (struct shape, method signatures, error sentinels, and test scenarios all stated in the issue body), the research and planning phases collapse into a single short pass. This is a documented pattern across many past retros.

Entry criteria for compact mode:

- The issue body fully specifies the public API or the deliverable.
- No design questions remain unanswered.
- The diff is bounded (a single new package, a single file, or a small set of related edits).

Disqualifiers (any one forces the full research + planning pass, even when every entry criterion is met):

- **Staleness drift.** Run `.github/ace-fca/scripts/compact-mode-check.sh <issue>` and read its `COMPACT_MODE:` verdict. Any merged PR that touched a referenced package or cited plan file since the issue was filed (drift > 0) disqualifies compact mode: the issue's stated shape may no longer match the code it builds on. An issue with no parseable artifacts yields an inconclusive staleness result, which is never a disqualifier by itself; eligibility then falls back to the entry criteria plus the risk-class gate.
- **Risk class.** Disqualify if ANY of these holds. (a) The tool name or issue title contains a decision-output or open-ended-investigation verb: `rank`, `score`, `recommend`, `compare`, `suggest`, `prioritize`, `estimate`, `research`, `investigate`, `spike`. (b) The issue cites a decision-output or metric-policy contract, meaning a plan section that constrains what the output may be computed from (for example a plan section that constrains what the output may be computed from), not merely what fields it carries. (c) The deliverable emits a decision field such as `decision_basis`, `source_of_truth`, or a provenance / justification / confidence value. The script auto-disqualifies on (a) and (c); (b) is a fuzzy citation heuristic, so the script prints it as a `RISK_CLASS_ADVISORY` line that you must judge and disqualify by hand when the cited section really constrains the output's inputs.

Even when compact mode is eligible, it must still emit a research document; only the planning phase may collapse. Paste the `COMPACT_MODE:` verdict into that research doc's compact-mode subsection (script for determinism, pasted verdict for auditability, mirroring the CCR-request playbook below). The minimum compact research doc contains: the original prompt, the referenced-artifact list, the staleness subsection with the pasted verdict, and a reused-infrastructure inventory. Writing any code before understanding the problem is the risk this guards against, so the research pass is never skipped.

Even in compact mode, **the implementation, post-implementation review, code-review, and retrospective phases are non-negotiable**. The discipline is in the post-implementation gate (`make review` clean, coverage, integration smoke), not in the ceremony of upstream artifacts.

## Research phase

In the research phase, use the .github/ace-fca/prompts/research.prompt.md to create a research document.

Use the details in the GitHub issue as input to the research document.

- ONLY do research.
- DO NOT implement anything.
- DO NOT make recommendations.
- USE the GitHub MCP

The output of this phase is a single document in .github/ace-fca/research/ which will be used in the planning phase.

## Planning phase

In the planning phase, use the .github/ace-fca/prompts/planning.prompt.md _and the research document you generated in research phase_ to create a comprehensive implementation plan.

Use the details and the Exit Criteria from the GitHub issue to understand the desired end state.

- DO NOT implement anything.
- USE the GitHub MCP

IMPORTANT: follow the instructions in .github/instructions/*.instructions.md when planning.

The output of this phase is two documents:

- a plan in .github/ace-fca/plans that will be used in the implementation phase
- a retrospective document in .github/ace-fca/retros that will be used in the retrospective phase

IMPORTANT: this phase is NOT complete UNTIL there are no unanswered questions.  The plan MUST have NO ambiguity.  If you cannot complete the plan, STOP and ask for help.

### Planning conventions

- **Map each issue success-criterion bullet to a test name.** When the plan lists tests, each one should mirror a checklist item from the issue body (e.g. `TestRecentWalletJournal_LimitDefaultAndCap` for "limit > 1000 is capped"). This makes the linkage obvious at code-review time.
- **Plan the integration test alongside the module.** When a new module needs integration coverage, plan the matching `test/integration/<module>_test.go` as a step-2 deliverable, not as gate backfill, so per-module PRs do not accumulate a backlog of missing tests.
- **For multi-module phases, write a one-page composition-shape ADR before parallel work starts.** Lock the constructor signatures (e.g. who takes `*pricing.Client` vs `*market.Module`; whether `charID` is resolved once in `main` or threaded through each module) before spawning parallel implementation sessions. Phase-2 modules diverged on composition (harmlessly, this time) because each PR re-decided.
- **Always copy YAML front matter from a recent neighbor** when creating any new document in `.github/ace-fca/{plans,research,retros}/`. The convention is repository-wide; reviews catch missing blocks.

## Refine plan phase

After planning, use .github/ace-fca/prompts/refine-plan.prompt.md to review the plan for:

1. **Decision debris** - remove pros/cons lists for rejected alternatives, historical context about rejected options, and redundant items
2. **Missed opportunities** - identify code quality improvements in the files being modified

The output of this phase is a refined plan document ready for implementation.

## Implementation phase

In the implementation phase, use the .github/ace-fca/prompts/implement-plan.prompt.md _and the planning document you generated in planning phase_ to implement the plan.

IMPORTANT: follow the instructions in .github/instructions/*.instructions.md when implementing.

The output of this phase will be the feature or bug fix specified in the GitHub issue.

### Implementation conventions

- **Co-land small infrastructure with the first consumer.** When new shared infrastructure is needed (a helper, or a new method on an internal client), add it in the same PR as the first user, with its own focused unit tests. Avoids speculative APIs and keeps the change reviewable.
- **When extending a shared infrastructure method, audit every existing caller for request-derived metadata** (method, headers, status), so a newly shared code path does not silently hardcode a value that was correct for only one caller.

## Post-implementation review phase

After implementation, use .github/ace-fca/prompts/post-implementation.prompt.md to review the modified code for:

1. Technical debt (duplicate code, unused functions, tight coupling)
2. Long functions (>50 lines, multiple responsibilities)
3. Leaky abstractions (provider-specific types in interfaces)
4. Complex logic (nested conditionals, unclear flow)
5. Style guide violations
6. Bad comments

The output of this phase is quality-reviewed code ready for retrospective.

### Code-review request playbook

When the implementation lands in a PR, request Copilot Code Review explicitly:

```bash
gh api -X POST repos/OWNER/REPO/pulls/N/requested_reviewers \
  -f 'reviewers[]=copilot-pull-request-reviewer[bot]'
```

Then **verify** that the request landed, by reading the issue timeline for a `review_requested` event naming `Copilot`:

```bash
gh api repos/OWNER/REPO/issues/N/timeline \
  --jq '.[] | select(.event == "review_requested") | .requested_reviewer.login'
```

Verify against the timeline, not against `requested_reviewers`. The expected login is `Copilot` (capital C, app `copilot-pull-request-reviewer`). The REST endpoint returns 200 even when the login casing is wrong and silently drops the request, so reading back is the only way to know it landed, but the pull request's own `requested_reviewers` array is unreliable for this bot: it can stay empty on a request that succeeded, which reads as a false negative and invites a pointless retry loop. Do **not** use `gh pr edit --add-reviewer Copilot`; that command requires `read:org` scope which the agent token lacks.

Once the review is submitted, confirm it landed and that nothing is outstanding:

```bash
gh api repos/OWNER/REPO/pulls/N/reviews --jq '.[] | {user: .user.login, state: .state}'
```

Wait for the review to complete, address every comment, and confirm all threads are resolved before merging.

Treat CCR as an iterative loop, not a single pass. After you fix or address the comments from one review and resolve their threads, request a fresh CCR (same REST call, re-verify the timeline event) and wait again. Repeat request -> wait -> fix/address -> resolve -> re-request until a review returns with no actionable comments. A clean pass with zero new comments is the only exit condition. Resolve a thread only once its comment is fixed or answered in a reply; the mutation is:

```bash
gh api graphql -f query='mutation($t:ID!){ resolveReviewThread(input:{threadId:$t}){ thread { id isResolved } } }' -f t="$THREAD_ID"
```

Fetch unresolved thread ids with the `reviewThreads` GraphQL field on the pull request.

### Pre-idle self-check (delegated work)

Before going idle on a delegated implementation task, print this checklist back:

- [ ] Did I write `.github/ace-fca/retros/<n>-<slug>.md`?
- [ ] Is the retro file included in the PR diff?
- [ ] Did I push the latest commit?
- [ ] Did I request Copilot review and confirm a `review_requested` timeline event naming `Copilot`?
- [ ] Are all Copilot review comments resolved?
- [ ] For each CCR finding, did I record it under "What the local review missed" and add a generalized, deduped local check (or note why none was warranted)?

This list exists because a worker session once merged a PR with green CI and resolved comments but never wrote a retrospective.

## Retrospective phase

In the retrospective phase, use the .github/ace-fca/prompts/retrospective.prompt.md to run a retrospective using:

- the retrospective document created in the planning phase
- the planning document created in the planning phase
- the research document created in the research phase.

The output of this phase will be an updated retrospective document.

### Step 0: ask the user for feedback first

**CRITICAL**: before writing or updating the retrospective, call `ask_user` to solicit the user's feedback on the cycle. Do not self-draft a retro and then ask for feedback on a second pass. The user's verbatim feedback is the most valuable signal in the retrospective and must be captured before the agent's own analysis colors it. (`0001-readme-phase-0a.md` flagged this gap; the prompt-level fix lives here in case the prompt itself is missed.)
