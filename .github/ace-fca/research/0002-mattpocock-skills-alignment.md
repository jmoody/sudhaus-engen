---
date: 2026-11-02 20:49:55 CET
researcher: "GitHub Copilot"
agent_llm: "Auto mode"
git_commit: b00c99491a1d499766a27d63b3d3769d2becf1ff
branch: main
repository: sudhaus-engen
topic: "Aligning ACE-FCA with Matt Pocock skills"
tags: [research, ace-fca, skills, workflow]
status: complete
last_updated: 2026-11-02
last_updated_by: "GitHub Copilot"
last_updated_note: "Compared ACE-FCA prompt files with Copilot CLI skills"
---

# Research: Aligning ACE-FCA with Matt Pocock skills

## Original Prompt

> In this repo I have the defined the ACE-FCA workflow defined in files in .github/ace-fca and .github/agents/ace-fca.agent.md and I have bunch of existing skills. I want to make sure the existing workflows, prompts, and skills align with the mattpocock skills.

---

## Summary

The two systems share the same core shape: research and planning are distinct from implementation, implementation is verified, review is a separate quality gate, and retrospectives feed learning back into the process (`.github/ace-fca/README.md:7-22`; `.github/agents/ace-fca.agent.md:64-195`). The Matt Pocock skills add more explicit methods at those seams: primary-source research, test-seam agreement and red-green vertical slices, ticket blocking graphs, a decision-tree workflow for uncertain work, two-axis code review, and environment-focused retrospectives (`engineering/research/SKILL.md:3-12`; `engineering/tdd/SKILL.md:18-36`; `engineering/to-tickets/SKILL.md:9-65`; `productivity/grilling/SKILL.md:6-30`; `engineering/code-review/SKILL.md:3-9`; `engineering/retro/SKILL.md:9-44`).

Converting ACE-FCA's phase prompts into skills is a stronger CLI-oriented option than only adding a routing layer. GitHub lists agent skills as supported in Copilot CLI, but not prompt files as a native CLI customization feature ([GitHub customization support matrix](https://docs.github.com/en/copilot/reference/customization-cheat-sheet#ide-and-surface-support)). The current agent can still follow prompt files by reading their paths directly (`.github/agents/ace-fca.agent.md:65-185`). Repackaging those phases as discoverable skills can retain ACE-FCA's artifacts, phase boundaries, compact-mode gate, verification, and iterative Copilot Code Review while routing to compatible existing skills.

This comparison reads the installed Matt Pocock skill files and official Copilot CLI documentation as primary sources. It does not assert that the installed skills match a current upstream release, and it does not evaluate the proposed migration by running it.

## Compact-mode eligibility

Not applicable: this research does not target a GitHub issue.

## Coverage map

| Workflow concern        | Matt Pocock skill(s)                             | Existing repository mechanism                            | Relationship and evidence                                                                                                                  |
| ----------------------- | ------------------------------------------------ | -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| Research                | `research`                                       | ACE-FCA research prompt and research directory           | Strong fit; both produce a cited artifact (`research/SKILL.md:3-12`; `.github/ace-fca/prompts/research.prompt.md:92-123`).                 |
| Decisions and discovery | `grilling`, `domain-modeling`, `wayfinder`       | Interactive planning and decision records                | Complementary; tree/frontier handles dependent decisions (`grilling/SKILL.md:6-30`; `.github/ace-fca/prompts/planning.prompt.md:113-168`). |
| Specification/tickets   | `to-spec`, `to-tickets`                          | GitHub issues, ACE-FCA plans, compact-mode gate          | Compatible; select artifact and task graph by work shape (`to-spec/SKILL.md:1-19`; `to-tickets/SKILL.md:9-65`).                            |
| Design and tests        | `codebase-design`, `tdd`                         | Go instructions, plan criteria, conditional TDD          | Compatible; make seams and TDD explicit (`tdd/SKILL.md:18-36`; `.github/ace-fca/prompts/implement-plan.prompt.md:48-56`).                  |
| Implementation          | `implement`, `implement-spec`                    | ACE-FCA implement-plan prompt and verification gate      | Same purpose, different orchestration (`implement/SKILL.md:9-17`; `implement-spec/SKILL.md:11-42`).                                        |
| Review                  | `code-review`                                    | ACE-FCA post-review, local code-review prompt, CCR       | Complementary local/spec review and external CCR (`code-review/SKILL.md:3-9`; `.github/skills/ccr-loop/SKILL.md:1-17`).                    |
| Learning/documentation  | `retro`, `writing-for-agents`, `domain-modeling` | ACE-FCA retrospective, ADR skill, domain docs, templates | Complementary; apply repo conventions (`retro/SKILL.md:9-44`; `writing-for-agents/SKILL.md:10-39`).                                        |
| Other workflow          | `triage`, `handoff`, `grill-me`                  | Issue-tracker documentation and project instructions     | Adjacent; invoke only for the corresponding task (`triage/SKILL.md:1-18`; `handoff/SKILL.md:1-14`).                                        |

The installed engineering skills also include `diagnosing-bugs`, `improve-codebase-architecture`, `ask-matt`, `grill-with-docs`, `setup-matt-pocock-skills`, and `pr`. They are specialized or setup-oriented and do not need to be inserted into every ACE-FCA cycle. The installed productivity skills include `to-questionnaire`, `teach`, `wait-what`, and the writing skills; these are likewise task-triggered rather than mandatory workflow phases. The inventory is the installed tree read on 2026-11-02, not a claim about a fixed upstream catalog.

## Detailed findings

### 1. Workflow phases align; skill routing is not yet explicit

ACE-FCA names a six-stage lifecycle, requires a fresh conversation per stage, and links each stage to a local prompt. The agent definition separately describes the same phases and calls those prompt files directly. The checked-in `README.md`, agent definition, and prompts do not include a phase-to-Matt-Pocock-skill map (`.github/ace-fca/README.md:7-22`; `.github/agents/ace-fca.agent.md:1-9, 64-195`).

Matt Pocock skills are a set of focused operations rather than a single lifecycle. `research` creates a source-cited research artifact; `to-spec` creates and publishes a spec; `to-tickets` decomposes approved work; `implement` and `implement-spec` execute work under different orchestration models. These can be selected by branch in an ACE-FCA phase rather than replacing ACE-FCA's phase boundaries (`research/SKILL.md:3-12`; `to-spec/SKILL.md:1-19`; `to-tickets/SKILL.md:1-9`; `implement/SKILL.md:1-17`; `implement-spec/SKILL.md:9-42`).

**Alignment implication:** package the phase-specific behavior as ACE-FCA skills, with a short entry point that identifies each phase and the existing skills it uses. Keep the research, plan, retrospective, and decision-record conventions; preserve project ADRs in `docs/adrs/`. This is a proposal, not an adopted workflow.

### 1a. Converting prompt files to skills

Copilot CLI supports project skills in `.github/skills/<name>/SKILL.md`, with a unique name, a description, and optional supporting files. The CLI can select a skill from its description or a user can invoke one by name; the selected skill's instructions are injected into the current context ([Adding agent skills for Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills)). A skill does not itself create a fresh conversation or enforce an approval gate, so ACE-FCA must continue to state and observe its phase boundaries.

The repo already has a packaging precedent: `ccr-loop` is canonical in `.github/ace-fca/skills/ccr-loop` and exposed through `.github/skills/ccr-loop` (`.github/skills/ccr-loop/SKILL.md:9-11`). The same layout could expose uniquely named phase skills, such as `ace-fca-research`, `ace-fca-plan`, `ace-fca-implement`, `ace-fca-review`, and `ace-fca-retro`. Unique names matter because the current CLI skill inventory already includes `research` and a personal `code-review` (`copilot skill list`, 2026-11-02). Avoid claiming a particular collision-precedence rule without testing it.

Do not mechanically copy all seven prompts into seven large skills. Research, planning, implementation, review, and retrospective are distinct invocation points; standalone refinement and post-implementation review may instead be optional skills or clearly pointed-to steps within the appropriate phase. Reuse the existing `ccr-loop` and relevant Matt Pocock skills rather than copying their procedures. Choose explicit versus automatic invocation for each phase deliberately; the installed `writing-for-agents` mechanics describes the discoverability and context-load tradeoff (`productivity/writing-for-agents/SKILL-MECHANICS.md:5-22`). The behavior of any particular invocation-control field in this CLI was not tested here.

Migration would also update `.github/agents/ace-fca.agent.md`, `.github/ace-fca/README.md`, and retrospective instructions that currently target canonical review prompt files (`.github/ace-fca/prompts/retrospective.prompt.md:71-77`). The seven `.github/prompts/` entries are currently symlinks to `.github/ace-fca/prompts/`; their removal or replacement belongs in a migration, after references are updated. Retain `make review`, the compact-mode gate, CCR, and the explicit human handoffs.

### 2. Research practices align, with different defaults about scope

The Matt Pocock research skill explicitly requires primary sources, claim-level citations, one Markdown report, and the repository's existing notes convention (`research/SKILL.md:3-12`). The ACE-FCA research prompt requires a single artifact under `.github/ace-fca/research/`, asks for local evidence and references, and limits web research to when the user explicitly asks for it (`.github/ace-fca/prompts/research.prompt.md:92-123, 194-216`). These are compatible: use repository files and installed skill definitions as primary sources for workflow-alignment research, and use external primary sources when a research task's question calls for them.

ACE-FCA's research and planning phases normally prohibit recommendations in the research artifact and reserve decisions for planning (`.github/agents/ace-fca.agent.md:64-73`; `.github/ace-fca/docs/ace-fca+decision-records.md:25-34`). That is not a blanket conflict with the current request: the user expressly asked to check alignment, which entails identifying gaps and suggesting alignment changes. Preserve the normal observational rule for product or implementation research, but permit recommendations when the research request itself asks for an evaluation or alignment.

The local research prompt also prescribes an issue-specific initial response, GitHub-specific investigation, a mandatory original-prompt section, metadata generation, and fixed numbered filenames (`.github/ace-fca/prompts/research.prompt.md:35-91, 128-216`). Those are repository workflow choices, not requirements of the Matt Pocock research skill. Apply them when they serve the local artifact; do not treat them as requirements of the installed skill itself.

### 3. Decision-tree discovery fills a distinct planning need

The `grilling` skill models decisions as a tree, asks the currently unblocked frontier of questions in a round, and requires waiting for the user's answers before proceeding (`grilling/SKILL.md:6-30`). ACE-FCA planning already investigates first, asks focused questions, presents design options, and requires plans to have no open questions (`.github/ace-fca/prompts/planning.prompt.md:113-168, 220-256, 400-468`; `.github/agents/ace-fca.agent.md:91-96`).

The difference is useful for dependency structure: ACE-FCA specifies an interactive sequence, while grilling defines which decisions can be asked together without assuming answers to prerequisites. The `wayfinder` skill goes further for large, uncertain efforts: it separates decision tickets from implementation tickets and stops once the route is clear (`wayfinder/SKILL.md:7-13, 57-75, 105-128`).

**Alignment implication:** use `grilling` when the user wants a decision stressed or a plan clarified; use its tree/frontier model when decisions have dependencies. Use `wayfinder` only when unresolved decisions make a destination or plan unclear across multiple sessions. Once the decisions are settled, hand execution to the existing ACE-FCA research/plan/implement lifecycle. Do not create a wayfinder map for a small, already-specified issue.

### 4. Specs, implementation plans, and tickets have overlapping but distinct jobs

`to-spec` synthesizes a discussion into a user-facing spec and publishes it to the issue tracker. It asks for user confirmation of test seams, then applies the ready-for-agent label (`to-spec/SKILL.md:1-19`). Its template asks for an extensive list of user stories (`to-spec/SKILL.md:21-45`). `to-tickets` turns a spec, plan, or conversation into complete vertical slices with explicit blockers, gets approval of granularity and dependency edges, then publishes tickets in dependency order (`to-tickets/SKILL.md:9-65`).

ACE-FCA starts from a GitHub issue, uses its exit criteria, writes a detailed plan and a matching retrospective, and has a compact-mode path for tightly specified issues (`.github/agents/ace-fca.agent.md:46-96, 100-137`).

These approaches align around complete, verifiable work and human confirmation. The additional Matt Pocock concepts are useful when work naturally forms several dependent tickets. A single issue with a single implementation plan does not need a duplicate spec and ticket set. An issue split into executable tasks should use meaningful blocker edges; a wayfinder decision ticket should not be mistaken for an implementation slice.

**Alignment implication:** choose one canonical work shape for each request: (a) one well-specified issue and an ACE-FCA plan, (b) a spec plus blocked vertical-slice tickets for multi-issue delivery, or (c) a wayfinder decision map before either when the destination is still unclear. Avoid auto-generating a large user-story list or a task graph if neither adds useful execution structure.

### 5. TDD and seam agreement should be an explicit implementation input

The Matt Pocock `tdd` skill requires agreeing on public test seams before tests are written, then working red-green in one vertical slice at a time; it rejects bulk test-first horizontal slicing (`tdd/SKILL.md:18-36`). The `codebase-design` skill supplies consistent terms for module, interface, seam, adapter, depth, and leverage (`codebase-design/SKILL.md:10-22, 60-65, 99-108`).

ACE-FCA's implementation prompt says tests must be written first **when the plan specifies TDD**, which makes the decision optional and moves the seam choice into plan text (`.github/ace-fca/prompts/implement-plan.prompt.md:48-56`). Planning requires success criteria and maps issue criteria to test names, but does not require the user to confirm the proposed seams (`.github/agents/ace-fca.agent.md:92-101`). This is a meaningful omission if the intent is to apply the TDD skill consistently.

**Alignment implication:** when using `tdd`, add test seams to the approved plan and confirm them before coding; retain the repo's Go test conventions and `make review`. Use `codebase-design` as vocabulary when the seam or module interface itself is a design question. Do not require a separate user checkpoint for routine, already-settled test boundaries.

### 6. Implementation orchestration needs an explicit choice

The single-work `implement` skill invokes TDD where possible, asks for regular type/test checks, requests code review, and directs the agent to commit (`implement/SKILL.md:9-17`). `implement-spec` is a different, high-concurrency process: integration branch, one worktree and implementer subagent per ticket, merger subagents, and frontier-driven parallel work (`implement-spec/SKILL.md:11-42`).

ACE-FCA's implementation prompt executes an approved plan phase by phase, requires the repository's `make review`, and says to use subagents sparingly for targeted exploration (`.github/ace-fca/prompts/implement-plan.prompt.md:22-56, 240-280`). The repo's project workflow requires its own branch/PR, review, and verification conventions (`.github/copilot-instructions.md:33-58`). These are not interchangeable execution policies. In particular, `implement-spec` should not silently change ACE-FCA work into a multi-worktree integration workflow, and its commit instruction should not override the local PR/approval flow.

**Alignment implication:** choose `implement` for one planned issue when adopting the Matt Pocock TDD and code-review calls; use `implement-spec` only when the user has selected a multi-ticket, parallel integration-branch effort and the repository workflow supports its worktree and merge model. Otherwise retain the local implementation prompt, adding only compatible skill steps.

### 7. Local review and CCR cover separate review surfaces

Matt Pocock `code-review` deliberately separates standards compliance from spec fidelity, pins a fixed comparison point, finds the originating spec, and reports the two axes separately (`code-review/SKILL.md:3-9, 17-32, 58-78`). ACE-FCA's local code-review prompt reviews committed branch changes against `main` and applies an extensive repository-specific checklist (`.github/ace-fca/prompts/code-review.prompt.md:8-27, 35-90`). Post-implementation review is scoped to the current implementation and checks code quality (`.github/ace-fca/prompts/post-implementation.prompt.md:14-107`). CCR is a separate iterative GitHub review loop, with every actionable comment addressed and a clean subsequent review required (`.github/skills/ccr-loop/SKILL.md:1-17`; `.github/copilot-instructions.md:44-57`).

The two-axis model adds a useful explicit spec-fidelity check; it does not replace local Go/security/domain checks or the external CCR gate. Conversely, calling both local reviews without clarifying their scope and fixed point risks duplicate findings.

**Alignment implication:** treat local post-implementation review as the immediate quality pass, then use a code-review pass that explicitly checks both repository standards and originating requirements at the chosen fixed point, then retain CCR as the external PR gate. If one prompt already covers both axes for the same diff, do not repeat it solely to satisfy a skill name.

### 8. Retrospectives and agent-writing principles align, but need local adaptations

The Matt Pocock `retro` skill looks for navigation, automated-check, coding-standard, tool-economy, no-op, and information-access improvements, and requires reading the repo's own check commands before proposing new checks (`retro/SKILL.md:9-44`). `writing-for-agents` emphasizes progressive disclosure, precise context pointers, single sources of truth, and pruning stale or no-op instructions (`writing-for-agents/SKILL.md:10-39, 78-80`). ACE-FCA already captures CCR findings, maps them to local-gate gaps, and generalizes warranted checks into canonical review prompts (`.github/ace-fca/prompts/retrospective.prompt.md:71-86`).

The ACE-FCA retrospective additionally requests user feedback, a user-performance analysis, creative icebreakers, and metadata (`.github/ace-fca/prompts/retrospective.prompt.md:88-156, 177-248`). Those are local choices, not required by the Matt Pocock `retro` skill. The repository's ADR and Markdown conventions also take precedence over generic skill defaults. For example, project instructions use `docs/adrs/` and ask contributors to read existing ADRs; `domain-modeling` examples use `docs/adr/` and lazily create a glossary (`.github/copilot-instructions.md:5, 33`; `docs/agents/domain.md:1-16`; `domain-modeling/SKILL.md:10-40`). The local `adr-author` skill explicitly defers to repo-local conventions (`.github/skills/adr-author/SKILL.md:1-16`).

**Alignment implication:** add the Matt Pocock retrospective checks as a lens, not as another required report section for every task. Keep CCR capture and local-gate learning. Use `writing-for-agents` when changing agent-facing prompts, and preserve the local ADR path and project Markdown style. User questions should follow the user's chat preference rather than assuming an elicitation UI.

### 9. Generic environment assumptions must not override repository constraints

Matt Pocock's `handoff` skill says to save its document in the operating system's temporary directory (`handoff/SKILL.md:1-14`). This repository explicitly prohibits system temp locations and requires repo-local `tmp/` or `scratch/` (`.github/copilot-instructions.md:79-89`; `.github/ace-fca/prompts/research.prompt.md:48-56`). The local rule wins. More generally, the Matt Pocock skills are user-installed files; they are not a replacement for the repo's Go, Terraform, shell, security, and GitHub rules.

**Alignment implication:** state a consistent precedence rule: platform safety and repo-local instructions first, ACE-FCA artifact and phase policy next, then the compatible parts of an invoked Matt Pocock skill. When they conflict, keep the skill's useful method but replace its incompatible tool, path, branch, commit, or interaction default.

## Proposed decision tree

The following is a routing proposal for a future alignment change. It is not a statement that these routing decisions have already been adopted.

```text
Start: What is unsettled?
|
+-- The destination or major decisions are unclear across sessions
|   +-- Use grilling/domain-modeling to map the decision tree.
|   +-- If decisions form a large map, use wayfinder decision tickets.
|   +-- Resolve the frontier; then hand off to ACE-FCA for execution planning.
|
+-- The destination is known, but facts or codebase behavior are unknown
|   +-- Use research for primary-source, cited investigation.
|   +-- Save one artifact in .github/ace-fca/research/ using local conventions.
|
+-- The desired behavior and main design are settled
    +-- One issue / bounded deliverable
    |   +-- Use ACE-FCA plan; compact mode only when its existing gate passes.
    |   +-- Confirm TDD seams when TDD is selected.
    +-- Several independently verifiable deliverables
        +-- Use to-tickets for vertical slices and real blocker edges.
        +-- Use implement-spec only if parallel integration work is intended
            and the repo's worktree, PR, and verification rules can be honored.

After implementation:
+-- Local quality and spec review, respecting repo standards and the fixed point
+-- CCR loop on the PR, until a fresh review is clean
+-- Retrospective: user feedback, observed process friction, and warranted gate changes
```

The branch between `wayfinder` decision tickets and `to-tickets` implementation slices is important: the former resolve choices and stop when the route is clear; the latter deliver complete behavior. Their definitions make this distinction explicit (`wayfinder/SKILL.md:7-13, 57-75`; `to-tickets/SKILL.md:9-38`).

## Prioritized alignment changes

1. **Convert the ACE-FCA phase entry points to skills.** Define distinct, collision-resistant names and decide which optional phases need independent invocation. Keep a small ACE-FCA entry point, update prompt references and retrospective targets, and state that repo instructions, tool restrictions, paths, and approval policies take precedence.
2. **Make the TDD handoff deliberate.** Have plans name the test seams and whether TDD is selected; when selected, confirm the seams before implementation and use one red-green vertical slice at a time.
3. **Choose the artifact model by work shape.** Keep one-issue work in the existing ACE-FCA plan flow. Add `to-tickets` only for complete work that benefits from multiple tickets and explicit blockers. Reserve `wayfinder` for unsettled decision trees, not implementation backlogs.
4. **Clarify review composition.** Preserve local post-review, the repository-specific review checklist, and iterative CCR. Make the two-axis standards/spec review explicit without duplicating a second review of the same scope.
5. **Use `writing-for-agents` and `retro` as maintenance lenses.** Apply progressive disclosure, source-of-truth, and no-op checks when editing prompts; assess navigation, automation, and tool economy in retrospectives without requiring all optional retro decorations on every cycle.

## Limitations

This is a source comparison of the installed Matt Pocock skills, Copilot CLI documentation, and the checked-in repository workflow as of 2026-11-02. It does not verify the plugin repository's upstream state, run every skill, test invocation-control fields, or establish that a proposed migration is accepted. No workflow, skill, prompt, or project code was changed as part of this research.

## References

### Repository sources

- `.github/ace-fca/README.md:1-89` - ACE-FCA stage order, phase prompts, and artifact layout.
- `.github/agents/ace-fca.agent.md:1-195` - Phase policy, compact mode, execution conventions, CCR, and retrospective gate.
- `.github/ace-fca/prompts/research.prompt.md:1-324` - Research scope, sources, artifact structure, and local metadata rules.
- `.github/ace-fca/prompts/planning.prompt.md:1-580` - Interactive planning, issue/criteria mapping, plan creation, decision cleanup, ambiguity gate, and decision records.
- `.github/ace-fca/prompts/implement-plan.prompt.md:1-280` - Baseline verification, conditional TDD, implementation, and local quality review.
- `.github/ace-fca/prompts/code-review.prompt.md:1-167` and `.github/ace-fca/prompts/post-implementation.prompt.md:1-137` - Local review scopes and checks.
- `.github/ace-fca/prompts/retrospective.prompt.md:1-377` - CCR capture, feedback, and process-retro behavior.
- `.github/skills/ccr-loop/SKILL.md:1-77` and `.github/copilot-instructions.md:33-58` - Iterative CCR process and repository PR policy.
- `.github/skills/adr-author/SKILL.md:1-144`, `docs/agents/domain.md:1-16`, and `.github/copilot-instructions.md:5, 33` - Local ADR and domain-document conventions.
- `.github/instructions/markdown.instructions.md:1-30` - Markdown wrapping and table rules.

### Installed Matt Pocock skill sources

Paths below are the installed files under `/Users/moody/.copilot/installed-plugins/mattpocock/mattpocock-skills/skills/`.

- `engineering/research/SKILL.md:1-12` - Primary-source research, claim citations, one document, repository location.
- `engineering/wayfinder/SKILL.md:7-13, 57-75, 105-128` - Decision-ticket map and frontier.
- `engineering/to-spec/SKILL.md:1-45` - Spec synthesis, seam confirmation, issue publication, and template.
- `engineering/to-tickets/SKILL.md:9-65` - Vertical slices, blockers, approval, and publication.
- `engineering/tdd/SKILL.md:18-36` and `engineering/codebase-design/SKILL.md:10-22, 60-65, 99-108` - Seam agreement, red-green slices, design terms.
- `engineering/implement/SKILL.md:1-17` and `engineering/implement-spec/SKILL.md:9-42` - Single-work and parallel multi-ticket execution.
- `engineering/code-review/SKILL.md:3-9, 17-32, 58-78` - Fixed point, standards/spec review axes, and parallel reviewers.
- `engineering/retro/SKILL.md:9-44` and `productivity/writing-for-agents/SKILL.md:10-39, 78-80` - Retro lenses and agent-document design.
- `engineering/domain-modeling/SKILL.md:10-40` - Glossary and ADR examples.
- `productivity/grilling/SKILL.md:6-30` - Decision-tree method.
- `productivity/handoff/SKILL.md:1-14` - Handoff output location default.
- `productivity/writing-for-agents/SKILL-MECHANICS.md:5-22` - Invocation choices and router skills.

### Copilot CLI documentation

- [Copilot customization support matrix](https://docs.github.com/en/copilot/reference/customization-cheat-sheet#ide-and-surface-support) - CLI support for skills and prompt files.
- [Adding agent skills for Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills) - Project skill location, frontmatter, and invocation.
