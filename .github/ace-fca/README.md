# ACE-FCA prompts

Advanced Context Engineering with Frequent Intentional Compaction. A research → plan → implement workflow for AI coding agents.

**Key insight**: Context window management is everything. Compress exploration into structured artifacts, review at high-leverage points, maintain forward momentum.

**Rule**: Start a new conversation for each phase. Long conversations degrade quality.

## Workflow

```
Research → Plan → Refine → Implement → Post-Review → Retrospective
```

## Prompts

### 1. Research

**File**: `prompts/research.prompt.md`

Understand existing systems before making changes. Documents current state without recommendations. Output: research document in `research/`.

### 2. Planning

**File**: `prompts/planning.prompt.md`

Create actionable implementation plans. Includes automatic refinement steps (decision cleanup, ambiguity review). Output: plan document in `plans/`.

### 3. Refine plan

**File**: `prompts/refine-plan.prompt.md`

Run when planning produces insufficient quality. Removes decision bloat, identifies improvement opportunities. Use when automatic refinement wasn't thorough enough.

### 4. Implementation

**File**: `prompts/implement-plan.prompt.md`

Execute plans phase-by-phase. Includes automatic post-implementation quality review. Updates plan checkboxes as work progresses.

### 5. Post-implementation

**File**: `prompts/post-implementation.prompt.md`

Run when implementation review was insufficient. Reviews `git diff` for quality issues. Use when automatic review missed problems.

### 6. Retrospective

**File**: `prompts/retrospective.prompt.md`

Capture learnings after completion. Documents what worked, what didn't, process improvements.

## Extensions

| Extension           | Documentation                          |
|---------------------|----------------------------------------|
| Decision records    | `docs/ace-fca+decision-records.md`     |
| Retrospectives      | `docs/ace-fca+retrospectives.md`       |
| Refine plan         | `docs/ace-fca+refine-plan.md`          |
| Post-implementation | `docs/ace-fca+post-implementation.md`  |
| Document numbering  | `docs/ace-fca+incremental-numbering.md`|

## Directory structure

```
.github/ace-fca/
├── prompts/          # Workflow prompts
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
