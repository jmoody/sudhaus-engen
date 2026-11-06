# ACE-FCA + post-implementation extension

## Why post-implementation review exists

Implementation agents optimize for "tests pass" and "plan complete." This creates blind spots:

- Plan-induced debt from patterns that work but aren't ideal
- Incidental complexity from quick fixes
- Style drift under time pressure

## What we're adding

A quality review after implementation completes:

```
Research → Plan → Implement → Post-Review → Retrospective
```

## How it works

### Automatic (built into the `ace-fca-implement` skill)

Post-Implementation Quality Review runs before declaring completion:
- Reviews modified code for quality issues
- Classifies by severity (🔴 Critical, 🟡 Important, 🟢 Nice-to-have)

### Manual (standalone skill)

When automatic review is insufficient, invoke `/ace-fca-post-implementation` separately:
- Scopes to `git diff` changes only
- Presents findings one-by-one
- Updates retrospective with findings

## Retrospective integration

Findings go to retrospective under "ACE-FCA Improvements" → "Implementation Quality".

This closes the feedback loop: implementation issues inform better planning.
