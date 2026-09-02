# ACE-FCA + refine plan extension

## Why refine-plan exists

Single-pass planning produces low-quality output. Two consistent problems:

1. **Decision debris**: Interactive planning accumulates alternatives, pros/cons, rationale for rejected options. Useful during discussion, harmful in final plan.

2. **Missed opportunities**: Planning agents don't identify code quality improvements in files being modified.

## What we're adding

A refinement step between planning and implementation:

```
Research → Plan → Refine Plan → Implement → Post-Review → Retrospective
```

## How it works

### Automatic (built into planning-prompt.md)

Steps 5.5 and 5.6 run automatically before plan finalization:
- Step 5.5: Removes decision bloat
- Step 5.6: Identifies improvement opportunities

### Manual (standalone prompt)

When automatic refinement is insufficient, run `refine-plan-prompt.md` separately:
- Reviews plan for bloat and opportunities
- Presents findings one-by-one for human review
- Updates retrospective with findings

## Retrospective integration

Findings go to retrospective under "ACE-FCA Improvements" → "Planning Prompt".

This answers: Why did planning miss these issues? Data improves future planning prompts.
