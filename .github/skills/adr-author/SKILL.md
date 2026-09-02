---
name: adr-author
description: Author an Architecture Decision Record. Use when proposing or recording a significant technical decision (architecture change, new dependency, deploy topology, hard-to-reverse choice) that should land as an ADR in a repo's docs/adr/ directory.
---

# Authoring ADRs

An architecture decision record (ADR) captures an important architectural decision made along with its context and consequences. ADRs exist so future contributors understand the "why" behind significant choices. Repo-local conventions always win over the defaults here.

## Principles

- **One decision per ADR.** Each record addresses a single architecturally-significant requirement. Don't bundle multiple decisions.
- **Rationale over conclusion.** The reasoning matters more than the outcome. A reader who disagrees with the decision should still understand why it was made.
- **Immutability.** Don't alter existing information in an accepted ADR. Amend with dated additions, or supersede with a new ADR.
- **Timely.** Write the ADR when the decision is being made, not after the code ships. The context is freshest and the team can still course-correct.
- **Specific.** Use concrete metrics, system names, and tradeoffs. Vague rationale ("improves performance") doesn't help future readers.

## When to write one

The bar is high. Write an ADR for:

- Architecture, layering, or core data-flow changes that reshape how contributors think about the system.
- Major new dependencies, runtime patterns, or library categories the project will live with for years.
- Public API or persisted schema changes that are hard to migrate away from.
- Choices genuinely costly to reverse (storage format, auth model, deploy topology).
- Amending or superseding a prior ADR.

Skip for: routine refactors, bugfixes, dependency bumps, subsystem-internal design, or choices likely revisited within months. If you can't name a similar-stakes decision the repo has already recorded as an ADR, you're over-reaching.

## File conventions

1. Look for `docs/adr/` in the target repo. Match the existing numbering pattern (e.g., `0005-kebab-title.md`). Never invent a new filename pattern in an established directory.
2. If no ADR directory exists, default to `docs/adr/` with sequential numbering (`0001-kebab-title.md`) and confirm with the user.

## Structure

```markdown
---
title: Short descriptive title
description: One-sentence summary of what the ADR decides
---

# N. Title matching the filename

Date: YYYY-MM-DD
Owner: @handle (or multiple @handles)

## Status

Proposed | Accepted | Deprecated | Superseded by [NNNN](NNNN-....md)

## Context

## Decision

## Consequences

## Alternatives

## References
```

**Status values:**
- **Proposed**: Under discussion, open for feedback.
- **Accepted**: In effect after team review.
- **Deprecated**: No longer applies.
- **Superseded by [NNNN](...)**: Replaced by a newer ADR. Link both directions.

## Section guidance

### Context

- State the concrete problem. Name the system constraints, the forces at play (performance, security, operational friction, team capacity), and what the current approach fails at.
- A reader should understand why *now* without reading any other document.
- Include your organization's situation: team capacity, skills, existing infrastructure.
- Link to the originating epic or issue.
- Include specific metrics or numbers when available ("a 33% capacity loss", "requires PRs, CI, and merge queues for operational adjustments").
- If scope is limited, state it explicitly ("Capistrano artifacts are out of scope because...").
- Include a **Constraints** sub-list when there are hard requirements the solution must satisfy.

### Decision

- Open with one clear sentence stating what was decided.
- Follow with numbered implementation steps describing *how* it works concretely.
- Include an **Edge cases** subsection when the implementation has non-obvious boundary behavior (zero values, invalid input, uneven division, skipped resources).

### Consequences

- Plain bullet list mixing positive outcomes and tradeoffs.
- Every consequence must be concrete and specific. "Requires a process to rotate the pinned trusted root" is good. "Improves security" is hand-waving.
- If all consequences are positive, something is missing.
- Include follow-up work this decision implies (subsequent ADRs, migration steps, team onboarding).
- Note what gets harder or what locks in as a result.

### Alternatives

Each alternative gets its own subsection heading (`### A. Title` or `### Title (status quo)`). For each:

- **How it works**: One paragraph describing the approach concretely.
- **Pros**: What it gets right. Use a numbered list. Each item is a complete sentence, or several sentences, that fully explores one pro. Do not compress multiple points into a single item or force unrelated ideas together to save space — one point per numbered item.
- **Cons**: What it gets wrong. Use a numbered list. Each item is a complete sentence, or several sentences, that fully explores one con. Do not compress multiple points into a single item or force unrelated ideas together to save space — one point per numbered item.
- **Rejected because...**: One sentence closing with the specific reason this lost.

Numbered lists are deliberate: each item gets its own line so reviewers can comment on a single pro or con in a pull request review without the point being buried inside a dense paragraph.

Rules:
- Every alternative must be genuinely considered. "Do nothing" / status quo only counts if it's a real option with real tradeoffs stated concretely.
- Throwaway alternatives that nobody would actually choose don't count. If you can't articulate real pros for an option, it's not a genuine alternative — cut it.
- State what the approach *would look like*, not just why it's bad.
- An empty Alternatives section means the decision wasn't real. Find genuine alternatives or reconsider whether this needs an ADR.

### References

- Link PRs, issues, epics, related docs, and external resources.
- Use the format: `- [Title or description](URL)`

## Writing style

- Direct and specific. Lead with the concrete detail, then explain why it matters.
- Use "we" framing when describing team decisions.
- No filler words, no corporate AI-speak, no summary sentences that restate what the evidence showed.
- State your preference then immediately challenge it with the tradeoff or gap.
- Anchor claims to real work: link issues, PRs, and docs inline.
- Frame constraints as plain direct statements.
- Pros and cons described in terms that align with the team's actual needs and goals, not abstract qualities.

## Workflow

1. Open the ADR as a separate PR in **Proposed** status before the implementation PR merges.
2. If writing mid-implementation, stop, open the ADR PR, and link them.
3. Promote to **Accepted** only after team review.
4. Never silently rewrite an Accepted ADR. Minor amendments: add a dated note inline. Material changes: new ADR with supersession links in both directions.
5. Consider reviewing accepted ADRs periodically (e.g., when the system changes significantly) to confirm they still apply or mark them deprecated/superseded.

## Common mistakes

- Writing the ADR after the code merges (context is stale, team can't course-correct).
- Only-positive consequences — if nothing gets harder, you haven't thought hard enough.
- Listing alternatives nobody would actually choose just to make the chosen option look good ("rewrite in another language" with no real analysis).
- Silently rewriting an accepted ADR instead of amending or superseding.
- Burying the decision in the implementation PR instead of a standalone ADR PR.
- Skipping constraints in Context when hard requirements exist.
- Inventing a new filename pattern in an established directory.
- Promoting to Accepted without team review.
