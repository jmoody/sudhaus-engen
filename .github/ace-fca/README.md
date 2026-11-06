# ACE-FCA skills

Advanced Context Engineering with Frequent Intentional Compaction. A research → plan → implement workflow for AI coding agents.

**Key insight**: Context window management is everything. Compress exploration into structured artifacts, review at high-leverage points, maintain forward momentum.

**Rule**: Start a new conversation for each phase. Long conversations degrade quality. A skill injects its body into the conversation it is invoked from and does not start a session, so this separation is the human's job.

## Workflow

```
Research → Plan → Implement → Post-Review → Retrospective
```

Five phases. Code review is not a phase; `/ace-fca-code-review` is a local adversarial gate run inside the post-implementation phase, before the pull request goes to Copilot Code Review.

## Skills

Each phase body is a project skill under `skills/<name>/SKILL.md`, surfaced to the skills loader through a directory symlink in `.github/skills/`. Edit the files under `.github/ace-fca/skills/`.

Every skill carries `disable-model-invocation: true` and is entered only by its explicit slash command. The model never self-selects a phase.

### 1. Research

**Skill**: `ace-fca-research`, invoked with `/ace-fca-research`

Understand existing systems before making changes. Documents current state without recommendations. Output: research document in `research/`.

### 2. Planning

**Skill**: `ace-fca-plan`, invoked with `/ace-fca-plan`

Create actionable implementation plans against a closed section schema. Includes a mandatory pre-finalisation verification sweep delegated to a fresh subagent. Output: plan document in `plans/` and a matching retrospective in `retros/`.

### 3. Implementation

**Skill**: `ace-fca-implement`, invoked with `/ace-fca-implement`

Execute plans phase-by-phase. Updates plan checkboxes as work progresses.

### 4. Post-implementation

**Skill**: `ace-fca-post-implementation`, invoked with `/ace-fca-post-implementation`

Review the implemented diff for quality issues: technical debt, long functions, leaky abstractions, style drift.

### 5. Retrospective

**Skill**: `ace-fca-retro`, invoked with `/ace-fca-retro`

Capture learnings after completion. Documents what worked, what didn't, process improvements.

### Local code-review gate

**Skill**: `ace-fca-code-review`, invoked with `/ace-fca-code-review`

Adversarial review of the committed branch diff against the project's instruction files. Run inside the post-implementation phase, before pushing for Copilot Code Review.

## Extensions

| Extension           | Documentation                           |
| ------------------- | --------------------------------------- |
| Decision records    | `docs/ace-fca+decision-records.md`      |
| Retrospectives      | `docs/ace-fca+retrospectives.md`        |
| Post-implementation | `docs/ace-fca+post-implementation.md`   |
| Document numbering  | `docs/ace-fca+incremental-numbering.md` |

## Directory structure

```
.github/ace-fca/
├── skills/           # Workflow skills (SKILL.md per phase)
├── research/         # Research documents (0001-xxx.md)
├── plans/            # Implementation plans (0001-xxx.md)
├── retros/           # Retrospectives (0001-xxx.md)
├── decision-records/ # Architectural decisions (000-xxx.md)
├── docs/             # Methodology documentation
├── templates/        # Document templates
└── scripts/          # Automation scripts
```

## Archiving

Documents are archived when not in the last 10 by sequential number.

```bash
# Preview
.github/ace-fca/scripts/archive-documents.sh

# Execute
.github/ace-fca/scripts/archive-documents.sh --execute
```

Archived documents move to `archives/`. Run monthly or quarterly.
