---
date: YYYY-MM-DD HH:MM:SS TZ
retrospective_for: "path/to/plan/document.md"
researcher: "GitHub Copilot"
git_commit: [commit hash]
branch: [branch name]
repository: [repo name]
topic: "[Plan Topic] Retrospective"
tags: [retrospective, ace-fca, relevant-topic-tags]
status: [in-progress | complete]
last_updated: YYYY-MM-DD
last_updated_by: "GitHub Copilot"
---

# Retrospective: [Plan Topic]

**Date**: YYYY-MM-DD HH:MM:SS TZ
**Plan Document**: [Link to plan document]
**Git Commit**: [commit hash]
**Branch**: [branch name]

## Decision Records Created

[List any decision records created during this development cycle]

## References

- Plan document: `[path to plan document]`
- Related retrospectives: `[links to related retrospective documents]`
- Decision records: `[links to decision records created during this work]`
- Implementation artifacts: `[key files or commits from implementation]`

## Implementation Notes

*Real-time observations captured during implementation using trigger phrases*

## User Feedback Analysis

### Feedback for Copilot
[User's feedback about agent performance during this development cycle]

### Recommendations for Agent Improvement
[Specific recommendations for improving ACE-FCA prompts, instructions, or process based on user feedback]

### Feedback for User
[Analysis of user's self-reflection and constructive suggestions for user improvement]

## Technical Retrospective

### What went well
[Specific evidence from completed work with file:line references where applicable]

### What to keep doing
[Patterns and approaches that should be repeated in future development]

### What can be improved
[Concrete suggestions with reasoning for process or technical improvements]

### What was missing
[Gaps in process, tools, approaches, or considerations that should be addressed]

## What the local review missed

Copilot Code Review (CCR) findings on this cycle's pull request, and the local-gate gaps that let each one through. The goal is to convert every miss into a generalized local check so the next cycle catches that class of defect before push.

### CCR findings

Output of `.github/skills/ccr-loop/scripts/ccr-loop.sh capture <pr>` (one thread per line). Replace with "No CCR findings this cycle." when capture reports none.

```json
```

### Local-gate gaps and fixes

For each finding, name the gap in `code-review.prompt.md` or `post-implementation.prompt.md` that let it slip past the local review, and the generalized, deduped check added there (or the reason none was warranted).

## Creative Icebreakers

###  Metaphor reflecting collaboration dynamic and capabilities

### Creative analogy
[Objects, tools, natural phenomena, or concepts representing the collaborative relationship]

## Lessons Learned

### For Future ACE-FCA Iterations
[Key insights and recommendations for improving the methodology]

### Process Improvements
[Specific suggestions for workflow, tool, or collaboration enhancements]

### Prompt Evolution Recommendations
[Suggested improvements to research-prompt.md, planning-prompt.md, implement-plan-prompt.md, or retrospective-prompt.md]
