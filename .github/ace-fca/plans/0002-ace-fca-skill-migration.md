---
date: 2026-11-02 22:53:11 CET
researcher: "GitHub Copilot"
agent_llm: "claude-opus-5"
git_commit: bc61b8b1f1362e8373fedf93bd792830a1b4c8cc
branch: feat/ace-fca-skills
repository: sudhaus-engen
topic: "Migrating ACE-FCA phase prompts to Copilot CLI skills"
tags: [plan, ace-fca, skills, copilot-cli, workflow]
status: draft
research_document: ".github/ace-fca/research/0002-mattpocock-skills-alignment.md"
last_updated: 2026-11-05
last_updated_by: "GitHub Copilot"
---

# Plan: Migrating ACE-FCA phase prompts to Copilot CLI skills

## Original Prompt

> I can't believe that you done a deep enough planning session.

> continue please

> lets dig into the reasons we need refine plan. The plans have generally been low quality with a lot of clutter.

---

## Goal

Convert the ACE-FCA phase prompts into gated, namespaced Copilot CLI project skills, and replace the planning phase's cleanup-after-generation model with a closed plan schema that cannot accumulate the clutter the current prompt produces.

## Settled decisions

- **Skills own the phase content.** Prompt bodies move into `SKILL.md`. `.github/agents/ace-fca.agent.md` shrinks to a router that keeps phase order, compact mode, tool policy, the CCR playbook, and the pre-idle checklist.
- **Six skills**, replacing seven prompts: `ace-fca-research`, `ace-fca-plan`, `ace-fca-implement`, `ace-fca-post-implementation`, `ace-fca-code-review`, `ace-fca-retro`.
- **Every skill carries `disable-model-invocation: true`.** Phase entry stays a human act; the model cannot self-invoke a phase.
- **Every skill name carries the `ace-fca-` prefix.** A project skill named `research` or `code-review` deletes the installed skill of that name from the inventory entirely.
- **Canonical content lives under `.github/ace-fca/skills/<name>/SKILL.md`**, exposed through directory symlinks in `.github/skills/`, following the `ccr-loop` precedent.
- **`refine-plan` folds into `ace-fca-plan`** as a mandatory pre-finalisation verification step. Its declutter half is deleted together with planning Step 7.
- **The folded verification is mechanical and delegated.** It runs as searches with checkable output, dispatched to a fresh subagent, because a judgement-based self-review by the authoring session is the failure mode that makes Step 7 ineffective.
- **Plans follow a closed section schema.** Nothing outside the schema is permitted. `## Original Prompt` stays a body section because prompts are occasionally long and would be fragile to quote in YAML. One optional `## Deliverable content` section carries verbatim payload.
- **Scope validation is a gate, never a document section.**
- **`.github/prompts/` and `.github/ace-fca/prompts/` retire** once references move.
- **Prompt bodies port faithfully.** Only `planning.prompt.md` is rewritten; the rest change only where they reference retired paths.

### The closed plan schema

| Section                    | Holds                                                     | Required  |
| -------------------------- | --------------------------------------------------------- | --------- |
| frontmatter                | metadata, research link, status                           | yes       |
| `## Original Prompt`       | the originating prompt, verbatim                          | yes       |
| `## Goal`                  | what the plan delivers, one or two sentences              | yes       |
| `## Settled decisions`     | decisions as current truth, no rationale, no alternatives | yes       |
| `## Starting state`        | verified facts and file paths the plan builds on          | yes       |
| `## Out of scope`          | explicit non-goals                                        | yes       |
| `## Implementation phases` | `### Phase N` with steps and success criteria             | yes       |
| `## Verification`          | how completion is proven                                  | yes       |
| `## Deliverable content`   | verbatim payload when the deliverable is text             | optional  |
| `## References`            | links only, no prose                                      | yes       |

## Starting state

**The prompts.** Seven files under `.github/ace-fca/prompts/` totalling 1942 lines: `planning` (580), `retrospective` (377), `research` (324), `implement-plan` (280), `code-review` (167), `post-implementation` (137), `refine-plan` (77). `.github/prompts/` holds seven symlinks pointing at them. All seven carry VS Code prompt-file frontmatter (`agent: 'agent'`, `description:`), which Copilot CLI does not consume.

**The packaging precedent.** `ccr-loop` is canonical at `.github/ace-fca/skills/ccr-loop/` with a bundled `scripts/` directory, exposed by the directory symlink `.github/skills/ccr-loop`. It appears correctly in `copilot skill list`, so symlinked project skills load.

**Verified CLI behaviour.** Skill name precedence is Project > Personal > Plugin, and the shadowed skill is removed from the inventory entirely rather than deprioritised: a project skill named `research` erased the plugin `research`, and one named `code-review` erased both the personal and plugin entries. Both returned when the probes were deleted. `disable-model-invocation: true` is honoured on project skills: a fresh `copilot -p` session reported a gated probe absent and an ungated probe present, while `copilot skill list` showed both.

**Verification tooling.** `copilot skill list` is a non-interactive inventory harness. `/skills reload` and `/skills info` work in-session. A fresh `copilot -p` session reveals the model-visible inventory.

**Documented frontmatter** is `name`, `description`, `license`, and `allowed-tools`. `disable-model-invocation` is not in GitHub's documentation; it is a Claude-plugin field honoured in practice, so the gate rests on undocumented behaviour.

**Reference sites that must move.** `.github/agents/ace-fca.agent.md` cites prompts at lines 65, 78, 103, 112, 125, and 185. `.github/ace-fca/README.md` cites them at lines 19, 25, 31, 37, 43, 49, and 67. `retrospective.prompt.md:76-77` writes generalised checks back into `code-review.prompt.md` and `post-implementation.prompt.md` as separate canonical targets, and names `.github/prompts/` as symlinks. `.github/ace-fca/docs/ace-fca+refine-plan.md` documents the folded extension.

**Carried debt.** Four references to `.github/instructions/bash-scripting.instructions.md` exist across three files: `code-review.prompt.md:35`, `post-implementation.prompt.md:55`, and `implement-plan.prompt.md:63,199`. The file does not exist; the real file is `.github/instructions/bash.instructions.md`. Retro 0001:197 recommended this fix and it was never applied.

**Why the planning prompt is rewritten.** Of its 580 lines, roughly 50 describe the artifact and the rest describe behaviour. With no whole-document schema, agents invent one: plan 0001 has 11 top-level sections where the template names 3. The Scope Validation Checklist, defined as a pre-flight gate, materialised as a permanent document section of ticked boxes. Step 7 and `refine-plan` Part 1 carry near-identical Remove/Keep lists, and both route removed material to the research document, which is a sealed prior-phase artifact. The single bloat item the one recorded `refine-plan` pass found was cross-section repetition, a class neither list names, while four of its five improvement findings share one root cause: planning read the codebase narrowly instead of searching every site holding a value the plan changes.

**Shared scripts.** `.github/ace-fca/scripts/` holds `archive-documents.sh`, `changed-files.sh`, `compact-mode-check.sh` with `compact-mode-check.bats`, and `generate-metadata.sh`. They are used by more than one phase and stay shared rather than moving into skill directories.

**Repository state.** Branch `feat/ace-fca-skills`, cut from `main` at `bc61b8b`. The research document, this plan, and its retrospective are committed there as the first commit; the implementation lands on the same branch. Tracking issue: https://github.com/jmoody/sudhaus-engen/issues/26.

## Out of scope

- `ccr-loop`, `adr-author`, `fix-markdown`, and `terraform-review` are unchanged.
- No VS Code or other IDE support; Copilot CLI is the only target.
- No adoption of `to-spec`, `to-tickets`, `implement-spec`, or `wayfinder`.
- No change to `docs/adrs/`, the compact-mode gate's logic, or the CCR policy.
- No rewrite of the research, implement, post-implementation, code-review, or retrospective bodies beyond reference updates and the carried-debt fix.
- No archiving or rewriting of historical documents whose references become stale; plan 0001 and retro 0001 stay as written.

## Implementation phases

### Phase 1: Create the skill scaffolding

#### Implementation steps

1. Create `.github/ace-fca/skills/<name>/SKILL.md` for the six skills.
2. Port each prompt body verbatim, except `planning.prompt.md`, which Phase 2 rewrites. Replace the VS Code frontmatter with `name`, `description`, and `disable-model-invocation: true`.
3. Write each `description` to state the phase and its trigger, even though gated skills are not model-selected, so `copilot skill list` and `/skills info` stay readable.
4. Create the six directory symlinks in `.github/skills/`, matching the `ccr-loop` pattern.
5. Add `allowed-tools` only where a skill invokes a bundled script, and omit `shell` and `bash` so command execution still prompts.

#### Success criteria

- [ ] `copilot skill list` shows all six `ace-fca-*` skills under Project skills.
- [ ] `copilot skill list` still shows the plugin `research` and the personal `code-review`, proving no name was shadowed.
- [ ] A fresh `copilot -p` session reports none of the six as model-visible.
- [ ] `/skills info ace-fca-plan` resolves to the symlinked project path.

### Phase 2: Rewrite the planning skill around the closed schema

#### Implementation steps

1. Delete Step 7 (decision documentation review) outright.
2. Add the closed schema as the authoritative output contract, stating that no section outside it is permitted.
3. Fold `refine-plan` Part 2 in as a mandatory pre-finalisation verification step expressed as mechanical searches: for every value the plan changes, enumerate every file holding it; and compare sections for a fact stated in more than one place.
4. Delegate that sweep to a fresh subagent so the cold-read property survives, and require its findings to be resolved before the plan reaches `ready`.
5. Delete `refine-plan` Part 1.
6. State that the Scope Validation Checklist is a gate whose output never appears in the plan.
7. Define the plan `status` values `draft`, `ready`, and `complete`, which retro 0001:60 recorded as undefined.
8. Replace VS Code tool names (`semantic_search`, `read_file`, `manage_todo_list`) with Copilot CLI equivalents, per retro 0001:57.

#### Success criteria

- [ ] `ace-fca-plan` contains the closed schema and no Step 7.
- [ ] The verification step names its searches and its subagent delegation.
- [ ] No instruction routes removed material to the research document.
- [ ] `status` values are defined.
- [ ] No VS Code tool name remains in the skill body.

### Phase 3: Move the references and retire the prompts

#### Implementation steps

1. Rewrite `.github/agents/ace-fca.agent.md` as a router: keep phase order, compact mode, tool policy, the CCR playbook, and the pre-idle checklist; replace the six prompt citations with the slash-command entry points; state that repository instructions, paths, and approval policy take precedence over any invoked skill.
2. Record that `refine-plan` is no longer a phase, reducing the declared six phases to five.
3. Update `.github/ace-fca/README.md`: the workflow line, the per-phase entries, and the directory structure block.
4. Update `retrospective.prompt.md`'s write-back targets to the two review skills' canonical paths, and delete the sentence describing `.github/prompts/` as symlinks.
5. Rewrite `.github/ace-fca/docs/ace-fca+refine-plan.md` to document the folded verification step, or delete it and fold its content into the extensions table.
6. Delete the seven symlinks in `.github/prompts/` and the directory.
7. Delete `.github/ace-fca/prompts/`.

#### Success criteria

- [ ] `grep -rn "ace-fca/prompts/" --include=*.md .github docs` returns matches only inside `.github/ace-fca/retros/` and `plans/0001-site-rollout.md`.
- [ ] `.github/prompts/` and `.github/ace-fca/prompts/` no longer exist.
- [ ] The README workflow line names five phases and the six skills.
- [ ] The retrospective skill's write-back targets resolve to existing files.

### Phase 4: Fix the carried debt

#### Implementation steps

1. Replace `.github/instructions/bash-scripting.instructions.md` with `.github/instructions/bash.instructions.md` in the three ported bodies, at the four sites retro 0001:197 identified.

#### Success criteria

- [ ] `grep -rn "bash-scripting.instructions" --include=*.md .github` returns matches only inside `.github/ace-fca/retros/0001-site-rollout.md`.

### Phase 5: Verify the migration end to end

#### Implementation steps

1. Run `make review`.
2. Run `copilot skill list` and confirm the inventory.
3. Run a fresh `copilot -p` probe for model visibility.
4. Walk one phase end to end by invoking `/ace-fca-plan` and confirming the body loads and the schema is stated.
5. Confirm no symlink in `.github/skills/` dangles.

#### Success criteria

- [ ] `make review` passes.
- [ ] The six skills load, none is model-visible, and no installed skill was shadowed.
- [ ] `/ace-fca-plan` injects the rewritten body.
- [ ] `ls -L .github/skills/*` resolves every entry.

## Verification

`make review` is the gate. Skill behaviour is verified with `copilot skill list` for the full inventory, a fresh `copilot -p` session for the model-visible inventory, and `/skills info` for path resolution. Reference integrity is verified with the two `grep` commands named in the Phase 3 and Phase 4 success criteria. The migration is complete when `make review` passes, all six skills load gated, no installed skill is shadowed, and no dangling reference or symlink remains.

## References

- Tracking issue: https://github.com/jmoody/sudhaus-engen/issues/26
- Research: `.github/ace-fca/research/0002-mattpocock-skills-alignment.md`
- Retrospective: `.github/ace-fca/retros/0002-ace-fca-skill-migration.md`
- Prior retro recording the refine-plan pass and the carried debt: `.github/ace-fca/retros/0001-site-rollout.md`
- Packaging precedent: `.github/ace-fca/skills/ccr-loop/SKILL.md`
- Workflow definition: `.github/ace-fca/README.md`, `.github/agents/ace-fca.agent.md`
- Markdown rules: `.github/instructions/markdown.instructions.md`
- [Adding agent skills for Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills)
