---
date: 2026-10-18 21:09:17 CEST
retrospective_for: ".github/ace-fca/plans/0001-site-rollout.md"
researcher: "GitHub Copilot"
git_commit: c4790005aa14abfab5866d68456b88b9ba2e6327
branch: main
repository: sudhaus-engen
topic: "Issue tree for the site rollout Retrospective"
tags: [retrospective, ace-fca, rollout, issues, planning]
status: complete
last_updated: 2026-11-01
last_updated_by: "GitHub Copilot"
---

# Retrospective: Issue tree for the site rollout

**Date**: 2026-10-18 21:09:17 CEST
**Plan Document**: `.github/ace-fca/plans/0001-site-rollout.md`
**Git Commit**: c4790005aa14abfab5866d68456b88b9ba2e6327
**Branch**: main

The batch issue https://github.com/jmoody/sudhaus-engen/issues/1 and the nine task issues https://github.com/jmoody/sudhaus-engen/issues/2 to https://github.com/jmoody/sudhaus-engen/issues/10 exist. All nine tasks are sub-issues of the batch, and the eleven dependency links match the plan's tree table.

## Decision Records Created

None.

## References

- Plan document: `.github/ace-fca/plans/0001-site-rollout.md`
- Research document: `.github/ace-fca/research/0001-site-rollout-requirements.md`
- Related retrospectives: none
- Decision records: none
- Implementation artifacts: the batch issue https://github.com/jmoody/sudhaus-engen/issues/1 and the task issues https://github.com/jmoody/sudhaus-engen/issues/2 to https://github.com/jmoody/sudhaus-engen/issues/10
- Pull request: https://github.com/jmoody/sudhaus-engen/pull/11

## Implementation Notes

*Real-time observations captured during implementation using trigger phrases*

- The baseline `make review` passed before the first change. The local commit `c479000` was then pushed to `origin/main` without a problem, because `main` has no protection.
- The `GH_TOKEN` and `GITHUB_TOKEN` variables held an expired token. `gh` returned `HTTP 401` on the first `gh issue create`, and the stored `gh` login was empty, so no fallback existed. The operator supplied a new token. A check of `gh auth status` and `gh api user` in Phase 1 step 2 would have caught this before any draft work, but the plan's check only reads `gh auth status`, which reported success on the first run. Check with an authenticated API call, not only the status text.
- The first creation script created the batch (https://github.com/jmoody/sudhaus-engen/issues/1) and then stopped. On macOS, `seq 1 0` counts down instead of printing nothing, so the placeholder loop for the first task read an unset array value. The script was rerun for the tasks only, after a check that exactly one issue existed. Avoid `seq` with a possibly empty range. Use a `while` loop. Check the issue list before every rerun of a creation script, so a rerun never creates duplicates.
- Each task draft held `{{Tn}}` placeholders for its blockers. The script replaced them with full issue URLs as it created the issues in dependency order, and it refused to create an issue that still held a placeholder. All ten bodies contain full URLs and no bare issue numbers.
- The plan says "Add an Issue column with the real numbers". The table holds full URLs instead, because the operator needs links that resolve.

## ACE-FCA Improvements

### Planning Prompt

Observations from the planning session of 2026-10-18.

- The prompt has no guidance for turning research into an epic, batch, and task tree. The operator's rule is that a task must stand alone: if the next task never happens, the PR is still complete and leaves no code that only a later task uses. Add this boundary test to the prompt.
- The first proposal had five batches and about 20 tasks. The operator found that too heavy. `docs/how-we-work.md` sizes a batch at 1-2 weeks, so the task count should be checked against that size before the first proposal.
- Questions about optional topics (DNSSEC, `security.txt`) tired the operator. The operator ended the topic with "Stop asking about DNSSEC." Ask only questions that change the task tree. State assumptions for the rest and let the operator object.
- Step 8 of the prompt says to write findings under "ACE-FCA Improvements" and "Planning Prompt", but the retro template has no such heading. This retro adds it. Add the heading to the template.
- The prompt names VS Code tools (`semantic_search`, `read_file`, `manage_todo_list`). The Copilot CLI has different tool names.
- The prompt's phase template (implementation steps and success criteria) fits code changes. For a plan whose output is issues, the phases are issue-creation steps. The prompt could say so.
- Research found that three referenced documents are not on `origin/main`. A check of `origin/main` for referenced files belongs in the plan's first phase when the output is GitHub text with links.
- The prompt defines no status values for a plan. This plan uses `draft` while the ambiguity review runs and `ready` after it, and the plan's last phase sets `complete`. Define the values in the prompt.
- The ambiguity review found a larger gap than the plan stated (finding 5: one commit with code, not three documents). Check `git log origin/main..HEAD` in the context-gathering step, not only the files the plan names.

### Refine-plan prompt findings

The refine-plan pass of 2026-10-18 found one bloat item and five improvement items. The operator accepted all six. The question for each is why planning missed it.

1. **Repeated gate and rationale text (bloat).** The plan stated the publication gate in four places and the T2 legal basis twice. Planning wrote each task section to stand alone and did not compare the sections afterward. The planning prompt's Step 7 lists "redundant items" but has no cross-section duplicate check. Add one.
2. **No shared render helper (improvement).** T1 split the template but did not say how pages render, so T2, T3, and T4 would each copy `handleIndex`. Planning read `web.go` for line numbers only. When several tasks add the same kind of thing (a page, a route, a resource), the plan must name the shared mechanism in the first task. Add this check to the prompt.
3. **Wrong routing guidance in `go.instructions.md` (improvement).** The file says the project uses chi, and `go.mod` holds no chi. Planning trusted the instruction files as correct. Add a step that compares the instruction files with `go.mod` and the code tree before tasks cite them.
4. **Stale provider lists (improvement).** `register-providers` and `terraform/README.md` repeat the provider list in the header comment, usage text, and prose counts. Planning named the array and the table only. Add a search for every other place that holds a value the plan changes.
5. **Past-state text in `main.tf` and the README (improvement).** Both say the root has no resources yet. Planning named one README sentence. The same search from item 4 finds this too, and the user's comment rule (current behavior only) applies to it.
6. **Timeout values left open (improvement).** T9 named three timeouts and no constants or values. Planning copied the research wording. A plan that adds a tunable value must say where it lives and who picks it.

### Ambiguity review findings

Step 8 of the planning prompt, one finding at a time.

1. **Log retention of 30 days.** The plan chose the value, which is the provider minimum. The operator confirmed it. T3, T5, and the batch exit criteria use the same value.
2. **Placeholder port.** The operator chose option A. T5 fixes the ingress `target_port` at 8000, the port the site uses. The placeholder image must answer on 8000. If no image works, T5 stops and reports, so the promote script never needs a Terraform change.
3. **T8 blocked by T4.** The operator chose option A. The domain goes live only after the brew-day list exists, so the public domain never shows placeholder text. T7 does not need T4 and can finish first.
4. **Script and make-target names.** The operator chose option A. T6 keeps `script/image-push`, `script/promote <sha>`, `make image-push`, and `make promote SHA=<sha>`. The name `image-push` shows that this build differs from the local `docker-build`.
5. **Local commit not on `origin/main`.** The plan named three missing documents. The real gap is commit `c479000`, which also holds the code that T1, T4, and T9 edit. The operator chose option A. Phase 1 pushes that commit straight to `origin/main`, because `main` is unprotected. A later draft pull request carries the plan and retro.

## User Feedback Analysis

### Feedback for Copilot

- "that is a lot of batches... could this not be a batch with a few tasks?"
- "something that I noticed in other epic, batch, task plans is that the tasks boundaries were artificial - meaning that task 1 would partially implement something for task 2, but review agents would churn on the partial implementation."
- "Stop asking about DNSSEC."
- "CI is failing.  Why haven't you addressed that first?"

The last comment came during the CCR loop. The agent had run `make review` locally, opened the draft pull request, and requested CCR without reading the three red CI checks. The operator found the failure. The comment is correct: a failing check is the first thing to read after a push, and it is cheaper to fix than a review round.

### Recommendations for Agent Improvement

- Verify GitHub access with an authenticated call (`gh api user`) before drafting, not with `gh auth status` alone.
- Before a rerun of any script that creates remote objects, list the objects that already exist.
- Write shell loops for macOS and Linux. Do not use `seq` with a range that can be empty.
- After every push, run `gh pr checks <pr>` before any other pull request step. Fix a red check before the CCR request. The agent now has this rule in `.github/ace-fca/prompts/post-implementation.prompt.md`.

### Phase and scope deviations

- The plan says "No application code, Terraform, or scripts in this plan". The CI fix changes four workflow files (`build.yml`, `lint.yml`, `test.yml`, `copilot-setup-steps.yml`), which none of those words name, but the change is outside the plan. The agent put it in this pull request without asking whether it should be a separate pull request.
- Root cause: the CI failure blocked the pull request, the operator asked why it was not fixed first, and the agent chose the shortest path. The plan has no rule for work found during the CCR loop that is outside the plan.
- Impact: benign. The change is 16 lines, and the CI checks passed on the pull request. A separate pull request would have kept the plan pull request to Markdown only. The agent did not offer that choice.
- Recommendation: when a fix is outside the plan, state that in one sentence and let the operator choose between the same pull request and a separate one.

### Feedback for User

- The decisions in the planning session were clear and early. The one slow point was the expired token, which the operator fixed in one step.
- The operator's rule that a task must stand alone, and the early "stop asking about DNSSEC", gave the plan a stable shape. Keep stating rules like these as soon as the first proposal shows a problem.
- The CI question was a good check on the agent. If the operator wants CI to be the first step after every push, the agent prompts should say so, and they now do.

## Technical Retrospective

### What went well

- The plan was complete enough to run without a design decision. Every title, body, and dependency came from the plan.
- Creating the issues in dependency order let each body hold real URLs for its blockers.
- The final checks (sub-issue count, per-task blocker lists, open-issue count) all matched the plan on the first run.
- The CCR loop found one real defect (a circular criterion) in round 1 and returned no comments in round 2. The fix reached both the plan and the issue.
- The CI fix was small and had one cause. After it, build, lint, and test all passed on the pull request.

### What to keep doing

- Keep the issue text in drafts under `./tmp/` until the issues exist, then delete the drafts.
- Run the baseline `make review` before any change, even for a plan that writes no code.

### What can be improved

- The creation script made the batch and the tasks in one run. A failure after the batch left a partial tree. Create the batch and the tasks as separate steps, and record each URL as soon as it exists.
- The plan's Phase 1 access check was too weak (see the implementation notes).
- The repository has contradicting statements about Terraform. `script/bootstrap-linux` and `script/bootstrap-macos` list `terraform` as a required dependency. The header of `script/terraform-lint` says the bootstrap contract treats Terraform as an operator-only tool and that the script exits 0 when Terraform is missing. One of the two is stale. The CI failure shows the bootstrap script is the one that runs.
- `.github/workflows/test.yml` starts a Postgres service and sets `SUDHAUS_ENGEN_POSTGRES_DSN`. No Go code, script, or Makefile target reads that variable. The step looks like a leftover from a template. It costs runner time on every run.
- The three prompts `code-review.prompt.md`, `post-implementation.prompt.md`, and `implement-plan.prompt.md` tell the agent to read `.github/instructions/bash-scripting.instructions.md`. That file does not exist. The real file is `.github/instructions/bash.instructions.md`.
- `.github/prompts/code-review.prompt.md` was a plain copy of the canonical prompt, and the other five files in that directory are symlinks. The retrospective prompt says the copies are symlinks. A prompt edit in `.github/ace-fca/prompts/` would not have reached the copy, so it is now a symlink.

### What was missing

- The plan gave no recovery step for a partial creation run. Add one: list the issues, keep what exists, and create only the rest.
- The plan and the implement prompt have no step that reads the CI result of the draft pull request. Add one, before the CCR request.

## What the local review missed

Copilot Code Review (CCR) findings on this cycle's pull request, and the local-gate gaps that let each one through. The goal is to convert every miss into a generalized local check so the next cycle catches that class of defect before push.

### CCR findings

Output of `.github/skills/ccr-loop/scripts/ccr-loop.sh capture 11`, taken after round 2:

```json
{"body":"This makes T8's completion criterion circular: the batch requires all nine tasks to be closed, including T8 itself, so this check cannot pass before T8 is closed. Limit this requirement to the batch's site-level checks and leave task closure to batch completion. The same wording is already present in https://github.com/jmoody/sudhaus-engen/issues/9, so update that issue as well.","id":"PRRT_kwDOVOExqs6yzXVO","isResolved":true,"line":null,"path":".github/ace-fca/plans/0001-site-rollout.md"}
```

Round 1 raised this one thread. Round 2 returned no comments. The fix is in the plan and in https://github.com/jmoody/sudhaus-engen/issues/9.

The CI checks (build, lint, test) also failed on the first push. CCR did not report this. All three failed in `script/bootstrap`, because `terraform` is a required dependency and the workflows did not install it. The failure was not new. The runners never had Terraform.

### Local-gate gaps and fixes

- Circular criteria. No local check covered completion criteria in plans and issue text. The check `Self-referential completion criteria` is now in the Focus areas of `.github/ace-fca/prompts/code-review.prompt.md`. It says a criterion must not depend on the closure of the item that owns it, or on a parent that requires that item to be closed.
- Local-versus-CI parity. `make review` runs on the operator's machine, which has Terraform, so it cannot show that a CI runner lacks a tool. The check `Local-versus-CI parity` is now in item 7 (Configuration consistency) of `.github/ace-fca/prompts/post-implementation.prompt.md`. Fixed in this pull request by adding `hashicorp/setup-terraform` to the four workflows that run `script/bootstrap`.
- Unread CI result. The agent requested CCR on a branch with three red checks. The new section `Pull request checks` in `.github/ace-fca/prompts/post-implementation.prompt.md` says to run `gh pr checks <pr>` before any review request, to fix a failing check first, and to read the checks again after every push.
- Not added as checks, recorded as recommendations below: the stale `bash-scripting.instructions.md` path, the `implement-plan` checklist, and the `terraform-lint` header. They are prompt and documentation defects, not review checks.

## Creative Icebreakers

### Metaphor reflecting collaboration dynamic and capabilities

A brew day with two thermometers. The agent read the one on the kettle (`make review` on the operator's machine) and not the one on the fermenter (the CI checks on the pull request). The operator walked by, looked at the second one, and asked why the agent had not read it first. The brewing schedule itself, the plan, was the operator's.

### Creative analogy

The issue tree is a brew-day checklist. The batch is the brew day, and each task is a step that must finish before the next step starts. The blocker links are the order of the steps. The circular criterion that CCR found is a step that says "wait until every step is done", written on step nine.

### Retrospective humor

This plan made ten issues and no code, and the only thing that broke was the thing that runs the code that does not exist yet.

## Lessons Learned

### For Future ACE-FCA Iterations

- A plan whose output is GitHub issues needs a recovery step for partial runs and an authenticated access check in its first phase.
- The first step after a push is to read the CI result. Review requests come after green checks.

### Process Improvements

- Record each created issue URL to a scratch file as soon as it exists, so a stopped run can resume.
- When a fix is outside the plan, say so in one sentence and let the operator choose the same pull request or a separate one.

### Prompt Evolution Recommendations

- Add "all CI checks pass" to the Pre-Completion Verification Checklist in `.github/ace-fca/prompts/implement-plan.prompt.md`. The `post-implementation` prompt now has the rule, and the checklist is the place the implementing agent reads last.
- Fix the path `.github/instructions/bash-scripting.instructions.md` to `.github/instructions/bash.instructions.md` in the three prompts that cite it.
- Decide whether Terraform is a required or an operator-only dependency. Then change either the bootstrap scripts or the header of `script/terraform-lint`, so that the two agree.
- Remove the Postgres service and `SUDHAUS_ENGEN_POSTGRES_DSN` from `.github/workflows/test.yml` if no task needs them.
- The prompt names VS Code tools (`replace_string_in_file`, `get_errors`, `get_changed_files`, `runSubagent`). Name the Copilot CLI tools, or describe the action instead of the tool.
- The prompt's code-quality checklist does not apply to a plan that creates issues and writes no code. Say which checks apply when a plan has no code output.
