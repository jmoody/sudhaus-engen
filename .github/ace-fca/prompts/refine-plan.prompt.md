---
agent: 'agent'
description: Refine ACE-FCA plans by removing bloat and identifying improvement opportunities.
---

# Refine plan

You are reviewing an ACE-FCA plan to make it implementation-ready. This prompt addresses two quality issues that planning agents consistently produce:

1. **Decision debris**: Plans accumulate "archaeology" from interactive discussions—alternatives considered, pros/cons, rationale for rejected options. Useful during planning, harmful for implementation.

2. **Missed opportunities**: Planning agents lack the sophistication to identify code quality improvements in the files being modified.

## Project guidelines

Refinements should align with project standards:
- **Primary**: `.github/copilot-instructions.md` - General coding guidelines and project conventions
- **Supplementary**: `.github/instructions/*.instructions.md` - Domain-specific style guides (Go, Bash, Markdown, etc.)

## Part 1: Remove decision bloat

Scan the plan for sections that document the decision process rather than the decision outcome.

**Remove**:
- Pros/cons lists for rejected alternatives
- Comparisons of approaches not chosen
- Historical context about why options were rejected
- Extensive rationale for decisions already made
- Multiple options without clear selection
- Redundant items (symptoms of other listed items)

**Keep**:
- The chosen approach stated clearly
- Constraints affecting implementation
- Design decisions informing how to code
- Edge cases needing handling

**For each bloated section**: Rewrite concisely. Move valuable context to research doc.

## Part 2: Identify improvement opportunities

Review code files referenced in the plan for opportunities that the planning agent missed. Use `list_code_usages` to assess the impact of proposed changes.

**Only consider code that will be modified by this plan.**

Check for:
1. **Technical debt**: Duplicate code, unused functions, tight coupling
2. **Long functions**: >50 lines, multiple responsibilities
3. **Leaky abstractions**: Provider-specific types in interfaces
4. **Complex logic**: Nested conditionals, unclear flow
5. **Bad comments**: Past state references, redundant explanations

For each opportunity found, determine if it should be:
- Added to the plan (if directly related to planned changes)
- Noted for future work (if tangential)
- Ignored (if out of scope)

## Process (INTERACTIVE)

Present findings ONE AT A TIME. After each finding, STOP and WAIT for human response.

**Format for each finding**:

```
**Type**: [Bloat removal | Improvement opportunity]
**Location**: [Section/file and line numbers]
**Issue**: [What's wrong]
**Suggested action**: [How to fix]

Proceed? (yes/no/modify/skip)
```

After all findings are addressed, update the retrospective under "ACE-FCA Improvements" → "Planning Prompt" with a summary of what was found. The question we're answering: Why did planning miss these issues?

## Goal

Produce a focused, unambiguous plan that an implementation agent can execute without wading through decision history, while also capturing code quality improvements the planning agent missed.
