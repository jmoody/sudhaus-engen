---
date: 2026-11-02 22:53:11 CET
researcher: "GitHub Copilot"
agent_llm: "claude-opus-5"
git_commit: bc61b8b1f1362e8373fedf93bd792830a1b4c8cc
branch: feat/ace-fca-skills
repository: sudhaus-engen
topic: "Migrating ACE-FCA phase prompts to Copilot CLI skills"
tags: [plan, ace-fca, skills, copilot-cli, workflow]
status: ready
research_document: ".github/ace-fca/research/0002-mattpocock-skills-alignment.md"
last_updated: 2026-11-06
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
- **`.github/prompts/` and `.github/ace-fca/prompts/` retire** once references move. Deletion is the last step before verification, so no phase can leave a repaired skill beside a deleted source.
- **Prompt bodies port faithfully.** Only `planning.prompt.md` is rewritten; the rest change only where they name a retired path, the wrong instructions file, or a VS Code tool.
- **VS Code tool names are replaced in every skill.** Copilot CLI is the only host, so no ported body may instruct the agent to call a tool the host does not have.
- **`.github/ace-fca/docs/ace-fca+refine-plan.md` is deleted**, together with its row in the README extensions table, because `refine-plan` ceases to be both an extension and a phase.

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

**Reference sites that must move.** `.github/agents/ace-fca.agent.md` cites prompts at lines 65, 78, 103, 112, 125, and 185. `.github/ace-fca/README.md` cites them at lines 19, 25, 31, 37, 43, 49, and 67, titles itself `# ACE-FCA prompts`, lists only five of the six phases (it has no `code-review` entry), and carries a `Refine plan` row in its extensions table. `retrospective.prompt.md:76-77` writes generalised checks back into `code-review.prompt.md` and `post-implementation.prompt.md` as separate canonical targets, and names `.github/prompts/` as symlinks; the same file names the retired `Refine` phase at line 11 and three `-prompt.md` basenames at line 89.

**Reference sites that cite a basename rather than a path.** These are invisible to a search for `ace-fca/prompts/` and were missed by the first draft of this plan. `.github/ace-fca/templates/retrospective-template.md:75,93` seeds every future retrospective with instructions to edit retired prompt files. `.github/ace-fca/scripts/README.md:71` describes `changed-files.sh` as scoping "the local `code-review.prompt.md` pass". `.github/ace-fca/docs/ace-fca+post-implementation.md:13,21,29` carries the six-phase diagram and two retired basenames. `.github/ace-fca/docs/ace-fca+refine-plan.md` documents the folded extension and is itself already stale: it cites `planning-prompt.md` and `refine-plan-prompt.md`, names that have never existed here, and describes "Steps 5.5 and 5.6" where the prompt has a Step 7.

**Carried debt.** Four references to `.github/instructions/bash-scripting.instructions.md` exist across three files: `code-review.prompt.md:35`, `post-implementation.prompt.md:55`, and `implement-plan.prompt.md:63,199`. The file does not exist; the real file is `.github/instructions/bash.instructions.md`. Retro 0001:197 recommended this fix and it was never applied.

**VS Code tool names in the prompt bodies.** Sixty-three occurrences of fifteen distinct names span all seven prompts: `semantic_search` (14), `read_file` (10), `manage_todo_list` (5), `grep_search` (5), `file_search` (5), `run_in_terminal` (4), `replace_string_in_file` (4), `get_changed_files` (4), `list_dir` (3), `list_code_usages` (3), `runSubagent` (2), and one each of `multi_replace_string_in_file`, `get_errors`, `fetch_webpage`, and `create_file`. Only the twenty-six in `planning.prompt.md` fall inside the rewrite; the rest reach the ported bodies, where they would instruct a Copilot CLI agent to call tools the host does not provide. Retro 0001:57 recorded this for the planning prompt alone.

**Why the planning prompt is rewritten.** Of its 580 lines, roughly 50 describe the artifact and the rest describe behaviour. With no whole-document schema, agents invent one: plan 0001 has 11 top-level sections where the template names 3. The Scope Validation Checklist, defined as a pre-flight gate, materialised as a permanent document section of ticked boxes. Step 7 and `refine-plan` Part 1 carry near-identical Remove/Keep lists, and both route removed material to the research document, which is a sealed prior-phase artifact. The single bloat item the one recorded `refine-plan` pass found was cross-section repetition, a class neither list names, while four of its five improvement findings share one root cause: planning read the codebase narrowly instead of searching every site holding a value the plan changes.

**Shared scripts.** `.github/ace-fca/scripts/` holds `archive-documents.sh`, `changed-files.sh`, `compact-mode-check.sh` with `compact-mode-check.bats`, and `generate-metadata.sh`. They are used by more than one phase and stay shared rather than moving into skill directories.

**Repository state.** Branch `feat/ace-fca-skills`, cut from `main` at `bc61b8b`. The research document, this plan, and its retrospective are committed there as the first commit; the implementation lands on the same branch. Tracking issue: https://github.com/jmoody/sudhaus-engen/issues/26.

## Out of scope

- `ccr-loop`, `adr-author`, `fix-markdown`, and `terraform-review` are unchanged.
- No VS Code or other IDE support; Copilot CLI is the only target.
- No adoption of `to-spec`, `to-tickets`, `implement-spec`, or `wayfinder`.
- No change to `docs/adrs/`, the compact-mode gate's logic, or the CCR policy.
- No rewrite of the research, implement, post-implementation, code-review, or retrospective bodies beyond reference updates, the carried-debt fix, and the VS Code tool-name replacement.
- No archiving or rewriting of historical documents whose references become stale; plan 0001 and retro 0001 stay as written.

## Implementation phases

### Phase 1: Create the skill scaffolding

#### Implementation steps

1. Create `.github/ace-fca/skills/<name>/SKILL.md` for the six skills.
2. Port each prompt body verbatim, except `planning.prompt.md`, which Phase 2 rewrites. Replace the VS Code frontmatter with `name`, `description`, and `disable-model-invocation: true`.
3. Write each `description` to name the phase and to state that the skill is invoked only by an explicit `/ace-fca-<phase>` command and must never be self-selected. The gate rests on undocumented behaviour, so the description is the fail-closed half: if a CLI upgrade stops honouring `disable-model-invocation`, a description that forbids self-selection is what remains, and a trigger-worded one would invite exactly the auto-invocation the gate exists to prevent.
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
8. Replace VS Code tool names with the Copilot CLI equivalents in `## Deliverable content`, per retro 0001:57. Twenty-six of the sixty-three occurrences are in this body.

#### Success criteria

- [ ] `ace-fca-plan` contains the closed schema and no Step 7.
- [ ] The verification step names its searches and its subagent delegation.
- [ ] No instruction routes removed material to the research document.
- [ ] `status` values are defined.
- [ ] No VS Code tool name remains in the skill body.

### Phase 3: Move the references and fix the carried debt

Every repair in this phase lands while the prompt tree is still present, so a ported body can always be compared against its source. Nothing is deleted here except the one extension document this migration retires.

#### Implementation steps

1. Rewrite `.github/agents/ace-fca.agent.md` as a router: keep phase order, compact mode, tool policy, the CCR playbook, and the pre-idle checklist; replace the six prompt citations with the slash-command entry points; state that repository instructions, paths, and approval policy take precedence over any invoked skill; and carry the fresh-conversation-per-phase rule explicitly, because a skill injects a body without starting a session.
2. Record that `refine-plan` is no longer a phase, reducing the declared six phases to five, and reconcile `ace-fca.agent.md:8` with `ace-fca.agent.md:54`, which disagree today on whether code review is a phase.
3. Update `.github/ace-fca/README.md`: the `# ACE-FCA prompts` title, the `## Prompts` heading, the workflow line, the per-phase entries including the missing `ace-fca-code-review` entry, the extensions table, and the directory structure block, which names `prompts/` and omits `skills/`.
4. Update the ported `ace-fca-retro/SKILL.md`, not the prompt it came from, at every site that names a retired artifact: the write-back targets at `retrospective.prompt.md:76-77`, which become the two review skills' canonical paths; the sentence in the same place describing `.github/prompts/` as symlinks, which is deleted; the phase list at line 11, which still names `Refine`; and the `-prompt.md` improvement list at line 89.
5. Update `.github/ace-fca/templates/retrospective-template.md:75,93` to name the `ace-fca-*` skills, so new retrospectives stop seeding instructions to edit retired files.
6. Update `.github/ace-fca/scripts/README.md:71` to name `ace-fca-code-review`.
7. Update `.github/ace-fca/docs/ace-fca+post-implementation.md:13,21,29`: the six-phase diagram and the two retired basenames.
8. Delete `.github/ace-fca/docs/ace-fca+refine-plan.md` and remove its `Refine plan` row from the README extensions table.
9. Replace `.github/instructions/bash-scripting.instructions.md` with `.github/instructions/bash.instructions.md` in the ported bodies, at the four sites retro 0001:197 identified.
10. Replace every VS Code tool name in all six ported bodies using the mapping in `## Deliverable content`. Where a prompt instructs the agent to call `get_changed_files`, name `.github/ace-fca/scripts/changed-files.sh`, which exists for exactly this purpose.

#### Success criteria

- [ ] `grep -rnE "(\.prompt\.md|-prompt\.md)" --include=*.md .github docs` returns matches only inside `.github/ace-fca/research/`, `.github/ace-fca/plans/`, and `.github/ace-fca/retros/`, which are historical artifacts this migration does not rewrite.
- [ ] `grep -rn "bash-scripting.instructions" --include=*.md .github` returns matches only inside `.github/ace-fca/retros/0001-site-rollout.md` and `.github/ace-fca/plans/0002-ace-fca-skill-migration.md`.
- [ ] `grep -rnE "\b(semantic_search|read_file|manage_todo_list|file_search|grep_search|list_dir|list_code_usages|fetch_webpage|run_in_terminal|create_file|replace_string_in_file|multi_replace_string_in_file|get_errors|get_changed_files|runSubagent)\b" .github/ace-fca/skills` returns nothing.
- [ ] The README workflow line names five phases and all six skills, and its extensions table has no `Refine plan` row.
- [ ] Every path named in `ace-fca-retro/SKILL.md`'s write-back instruction resolves to an existing file.
- [ ] `.github/ace-fca/docs/ace-fca+refine-plan.md` no longer exists and nothing links to it.

### Phase 4: Retire the prompt trees

Deletion runs only after Phase 3's repairs are verified, so an interrupted session can never leave a half-repaired skill beside a deleted source.

#### Implementation steps

1. Delete the seven symlinks in `.github/prompts/` and the directory.
2. Delete `.github/ace-fca/prompts/`.

#### Success criteria

- [ ] `.github/prompts/` and `.github/ace-fca/prompts/` no longer exist.
- [ ] `grep -rn "ace-fca/prompts/\|\.github/prompts/" --include=*.md .github docs` returns matches only inside `.github/ace-fca/research/`, `.github/ace-fca/plans/`, and `.github/ace-fca/retros/`.
- [ ] Phase 3's three greps still return the same results after the deletions.

### Phase 5: Verify the migration end to end

#### Implementation steps

1. Run `make review`.
2. Run `copilot skill list` and confirm the inventory.
3. Run a fresh `copilot -p` probe for model visibility, and record the Copilot CLI version the probe passed on, because `disable-model-invocation` is undocumented and the gate rests on it.
4. Walk one phase end to end by invoking `/ace-fca-plan` and confirming the body loads and the schema is stated.
5. Confirm no symlink in `.github/skills/` dangles.

#### Success criteria

- [ ] `make review` passes. It is the repository regression check, not the migration gate; the greps and skill probes are the migration gate.
- [ ] The six skills load, none is model-visible, and no installed skill was shadowed.
- [ ] `/ace-fca-plan` injects the rewritten body.
- [ ] `ls -L .github/skills/*` resolves every entry.
- [ ] The tested Copilot CLI version is recorded in the retrospective.

## Verification

The migration gate is the set of explicit probes, not `make review`. Reference integrity is verified with the three `grep` commands in the Phase 3 success criteria, re-run after Phase 4's deletions. Skill behaviour is verified with `copilot skill list` for the full inventory, a fresh `copilot -p` session for the model-visible inventory, and `/skills info` for path resolution. `make review` resolves to `build imports lint test` and validates no Markdown reference, skill load, frontmatter, or symlink, so it runs as the repository regression check and cannot stand in for the probes. The migration is complete when every grep returns only historical matches, all six skills load gated, no installed skill is shadowed, no symlink dangles, and `make review` passes.

## Deliverable content

The VS Code to Copilot CLI tool-name mapping applied in Phase 2 step 8 and Phase 3 step 10.

| VS Code tool name              | Copilot CLI equivalent                                                   |
| ------------------------------ | ------------------------------------------------------------------------ |
| `semantic_search`              | `semantic_code_search`, or `grep` narrowed by a file glob                |
| `read_file`                    | `view`                                                                   |
| `file_search`                  | `glob`                                                                   |
| `grep_search`                  | `grep`                                                                   |
| `list_dir`                     | `glob`, or `view` on a directory                                         |
| `list_code_usages`             | `grep` narrowed by a file glob                                           |
| `fetch_webpage`                | `web_fetch`                                                              |
| `run_in_terminal`              | `bash`                                                                   |
| `create_file`                  | `create`                                                                 |
| `replace_string_in_file`       | `edit`                                                                   |
| `multi_replace_string_in_file` | several `edit` calls in one response                                     |
| `get_errors`                   | `bash` running `make build` or `make lint`                               |
| `get_changed_files`            | `.github/ace-fca/scripts/changed-files.sh`                               |
| `manage_todo_list`             | the `sql` tool's `todos` table                                           |
| `runSubagent`                  | `task`                                                                   |

## References

- Tracking issue: https://github.com/jmoody/sudhaus-engen/issues/26
- Research: `.github/ace-fca/research/0002-mattpocock-skills-alignment.md`
- Retrospective: `.github/ace-fca/retros/0002-ace-fca-skill-migration.md`
- Prior retro recording the refine-plan pass and the carried debt: `.github/ace-fca/retros/0001-site-rollout.md`
- Packaging precedent: `.github/ace-fca/skills/ccr-loop/SKILL.md`
- Workflow definition: `.github/ace-fca/README.md`, `.github/agents/ace-fca.agent.md`
- Markdown rules: `.github/instructions/markdown.instructions.md`
- [Adding agent skills for Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills)
