---
date: 2026-11-02 22:53:11 CET
retrospective_for: ".github/ace-fca/plans/0002-ace-fca-skill-migration.md"
researcher: "GitHub Copilot"
agent_llm: "claude-opus-5"
git_commit: 6eebce6f7b9e47124dd8269adf2c90af92cc3c06
branch: feat/dataschutz
repository: sudhaus-engen
topic: "Migrating ACE-FCA phase prompts to Copilot CLI skills Retrospective"
tags: [retrospective, ace-fca, skills, copilot-cli, workflow]
status: in-progress
last_updated: 2026-11-02
last_updated_by: "GitHub Copilot"
---

# Retrospective: Migrating ACE-FCA phase prompts to Copilot CLI skills

**Date**: 2026-11-02 22:53:11 CET
**Plan Document**: `.github/ace-fca/plans/0002-ace-fca-skill-migration.md`
**Git Commit**: 6eebce6f7b9e47124dd8269adf2c90af92cc3c06
**Branch**: feat/dataschutz

This retrospective is created during planning and completed after implementation. Capture observations in real time with trigger phrases such as "add this to the retro".

## Decision Records Created

None. The decisions are recorded in the plan's "Settled decisions" section. If the orchestrator decision proves hard to reverse during implementation, author an ADR under `docs/adrs/` with the `adr-author` skill.

## References

- Tracking issue: https://github.com/jmoody/sudhaus-engen/issues/26
- Plan document: `.github/ace-fca/plans/0002-ace-fca-skill-migration.md`
- Research document: `.github/ace-fca/research/0002-mattpocock-skills-alignment.md`
- Related retrospective: `.github/ace-fca/retros/0001-site-rollout.md`
- Implementation artifacts: to be filled in after implementation.

## Implementation Notes

*Real-time observations captured during implementation using trigger phrases*

## ACE-FCA Improvements

### Planning Prompt

Observations from the planning session of 2026-11-02. These are findings about the prompt being migrated, gathered while planning its migration.

- **The prompt specifies behaviour far more than it specifies the artifact.** Of 580 lines, roughly 50 describe the plan document and the rest describe how to act. With no whole-document schema, agents invent one. Plan 0001 carries 11 top-level sections where the template names 3.
- **A pre-flight gate became a permanent document section.** The Scope Validation Checklist is defined as something to "verify before presenting plan", yet it appears in plan 0001:379-385 as a section of five ticked boxes. An implementer gains nothing from boxes confirming the planner did its job. The migration states that gates never reach the page.
- **Step 7 duplicates `refine-plan` Part 1.** The Remove and Keep lists are near-identical, and both route removed material to the research document. The same agent is told to perform the same cleanup twice.
- **The cleanup escape hatch points at a sealed artifact.** By planning time the research document is a completed prior-phase output, so debris routed there stays in the plan instead.
- **Step 7 asks an author to judge its own prose.** This is why it fires rarely. The folded verification in the new skill is deliberately mechanical and subagent-delegated to avoid inheriting the same failure.
- **`refine-plan`'s recorded value contradicts its stated purpose.** Retro 0001:63-71 shows its one pass found 1 bloat item and 5 improvement items. The bloat item was cross-section repetition, a class neither declutter list names, and four of the five improvements share one root cause: planning read the codebase narrowly. The new verification step targets that root cause directly.
- **Previously recorded but still open items now carried by this plan.** Undefined plan `status` values (retro 0001:60) and VS Code tool names in the prompt (retro 0001:57) are both fixed in Phase 2.

### Verification findings

Behaviour the research document listed as untested, resolved by experiment during planning.

- **Skill name precedence is Project > Personal > Plugin, and the loser is deleted from the inventory**, not merely deprioritised. A project skill named `research` erased the plugin `research`; one named `code-review` erased both the personal and plugin entries. This converted namespacing from a stylistic preference into a hard requirement.
- **`disable-model-invocation: true` is honoured on project skills.** A fresh `copilot -p` session reported a gated probe absent and an ungated probe present, while `copilot skill list` showed both. This validates the phase-gate design.
- **The field is undocumented.** GitHub documents `name`, `description`, `license`, and `allowed-tools` only. The gate therefore rests on behaviour that could change. Re-run the probe after any Copilot CLI upgrade.
- **`copilot skill list` is a usable non-interactive harness**, which answers the plan's verification question without needing an interactive session.

### Ambiguity review findings

Questions raised and settled with the operator during this planning session.

1. **Migration depth.** Option B: skills own the phase content and the agent file shrinks to a router. Options A (thin wrappers) and C (retire the agent file) were declined; C is unsafe because skills cannot enforce a gate or start a fresh conversation.
2. **Fate of `refine-plan`.** Folded into `ace-fca-plan` as a mandatory verification step, giving six skills. The operator chose folding over a separate re-scoped skill. The risk that a same-session pass recreates the Step 7 no-op is accepted and mitigated by mechanical searches plus subagent delegation.
3. **`## Original Prompt` placement.** Kept as a body section rather than demoted to frontmatter, because prompts are occasionally very long and would be fragile to quote and indent in YAML.

## User Feedback Analysis

### Feedback for Copilot

[To be completed after implementation. The operator's opening feedback on this cycle was that the prior session's planning was not deep enough, which prompted the empirical verification that produced the findings above.]

### Recommendations for Agent Improvement

[To be completed after implementation]

### Phase and scope deviations

[To be completed after implementation]

### Feedback for User

[To be completed after implementation]

## Technical Retrospective

### What went well

[To be completed after implementation]

### What to keep doing

- Resolving "not tested" claims by running a bounded experiment rather than carrying them forward as assumptions. Three open design questions were closed in minutes with `copilot skill list` and a `copilot -p` probe.

### What can be improved

[To be completed after implementation]

### What was missing

[To be completed after implementation]

## What the local review missed

Copilot Code Review (CCR) findings on this cycle's pull request, and the local-gate gaps that let each one through. The goal is to convert every miss into a generalized local check so the next cycle catches that class of defect before push.

### CCR findings

Output of `.github/skills/ccr-loop/scripts/ccr-loop.sh capture <pr>` (one thread per line). Replace with "No CCR findings this cycle." when capture reports none.

```json
```

### Local-gate gaps and fixes

For each finding, name the gap in the `ace-fca-code-review` or `ace-fca-post-implementation` skill that let it slip past the local review, and the generalized, deduped check added there (or the reason none was warranted).

## Creative Icebreakers

### Metaphor reflecting collaboration dynamic and capabilities

[To be completed after implementation]

### Creative analogy

[To be completed after implementation]

### Retrospective humor

[To be completed after implementation]

## Lessons Learned

### For Future ACE-FCA Iterations

[To be completed after implementation]

### Process Improvements

[To be completed after implementation]

### Prompt Evolution Recommendations

[To be completed after implementation]
