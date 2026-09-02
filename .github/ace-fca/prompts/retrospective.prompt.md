---
agent: 'agent'
description: Retrospective phase for ACE-FCA implementations.
---

# Retrospective Analysis with GitHub Copilot

## CRITICAL: RETROSPECTIVE-ONLY SCOPE

- **Retrospective phase focuses on analysis, feedback, and learning capture**
- **Your role is to analyze what happened and provide actionable improvement recommendations**
- **This is the final phase of ACE-FCA: Research → Plan → Refine → Implement → Retrospective**

## CRITICAL: Temporary file locations

**NEVER write to `/tmp` or any system temporary directory.**

- Use workspace-relative paths for all temporary files
- Create temporary directories in the project workspace (e.g., `./tmp/`, `./scratch/`)
- These directories are already gitignored and intended for temporary/generated content
- System `/tmp` is not accessible or appropriate for development workflows

## Initial Setup

When this command is invoked:

1. **If parameters provided**:
   - Read the completed plan document FULLY
   - Read any existing retrospective document FULLY
   - Begin retrospective analysis immediately

2. **If no parameters provided**, respond with:
```
I'll help you conduct a comprehensive retrospective analysis. This is the final phase of ACE-FCA methodology.

Please provide:
1. Path to the completed plan document (e.g., `.github/ace-fca/plans/000N-description.md`)
2. Path to retrospective document (if created during planning phase)
3. Your raw feedback and observations about:
   - What worked well in the agent's performance
   - What could be improved in future iterations
   - Any specific issues or successes during implementation
   - Your own experience and learning from the process

I'll analyze the completed work and provide comprehensive feedback for improving future ACE-FCA iterations.
```

## Process Steps

### Step 1: Context Gathering & Analysis

#### Read all mentioned files immediately and FULLY

- Completed plan document
- Existing retrospective document (if any)
- Any referenced implementation files or results
- **IMPORTANT**: Use read_file tool WITHOUT limit/offset parameters
- **CRITICAL**: Read these files completely before analysis

#### Review implementation changes

- Use `get_changed_files` to review what was actually modified during implementation, comparing actual changes to planned changes

#### Analyze the completed work

- Review plan phases and success criteria completion
- Examine implementation approach vs plan intent
- Identify any deviations or adaptations made
- Note any unresolved issues or incomplete elements

#### Capture CCR findings and close local-gate gaps

The pull request has been through the Copilot Code Review (CCR) loop, so every CCR thread is now resolved. Capture the full record and feed each miss back into the local review prompts so future cycles catch that class of defect before push:

1. Run `.github/skills/ccr-loop/scripts/ccr-loop.sh capture <pr>`; it prints every CCR-authored thread (resolved and unresolved) as JSON lines. Embed that output verbatim in the retrospective under `## What the local review missed` → `### CCR findings`. When capture reports no threads, record "No CCR findings this cycle." and skip the remaining sub-steps.
2. Under `### Local-gate gaps and fixes`, map each finding to the gap in the local review that let it through: name the check in `.github/ace-fca/prompts/code-review.prompt.md` and/or `.github/ace-fca/prompts/post-implementation.prompt.md` that should have caught it (or note that no local check covers this class yet).
3. **Curate and improve**: for each finding the local review missed, add a generalized, deduped check to the appropriate canonical prompt (`.github/ace-fca/prompts/code-review.prompt.md` and/or `.github/ace-fca/prompts/post-implementation.prompt.md`). Generalize the specific miss into a reusable rule rather than an over-specific one-off, and dedupe against existing bullets before adding. Edit only the canonical `.github/ace-fca/prompts/` files; the `.github/prompts/` copies are symlinks. These prompt edits land in the same pull request as the retrospective.

### Step 2: User Feedback Analysis & Response

#### Analyze user's "Feedback for Copilot" section

- Extract specific performance issues and successes
- Identify patterns in agent behavior that need improvement
- Note any recurring problems across multiple phases

#### Provide specific recommendations for

- **ACE-FCA prompt improvements**: Specific updates to research-prompt.md, planning-prompt.md, implement-plan-prompt.md
- **.github/instructions updates**: Improvements to instruction files based on implementation experience
- **Codebase architectural improvements**: Suggestions based on implementation challenges
- **Process workflow enhancements**: Better approaches for future similar work

#### Phase violation analysis

If the implementation included any phase violations:

##### Document what was done out of phase

Identify specific code changes during wrong phase.

##### Analyze root cause

Determine if it was ambiguous request, agent assumption, or missing prompt guidance.

##### Recommend specific changes

Propose prompt updates to prevent recurrence.

##### Impact assessment

Note whether the violation was benign or caused issues/rework.

### Step 3: User Performance Analysis

#### Review user's planning and implementation behavior

- Analyze decision-making patterns during planning
- Evaluate collaboration effectiveness during implementation
- Assess use of available tools and resources

#### Provide encouraging yet constructive feedback

- Answer user's technical questions with specific examples
- Highlight effective approaches that should be repeated
- Identify areas for growth with actionable suggestions
- Focus on collaboration patterns and communication clarity

### Step 4: Technical Retrospective Analysis

Conduct systematic analysis following established retrospective patterns:

#### What went well

With specific evidence from completed work.

#### What to keep doing

Patterns that should be repeated.

#### What can be improved

Concrete suggestions with reasoning.

#### What was missing

Gaps in process, tools, or approach.

### Step 5: Creative Icebreaker Generation

Following established patterns from `.github/ace-fca/retros/`, generate creative, personalized responses that make retrospectives engaging rather than purely analytical. Each icebreaker should be based on specific evidence from the collaboration.

#### Creative analogies

- Objects, tools, natural phenomena, or concepts that represent the collaborative relationship
- Focus on the working dynamic and communication patterns
- Examples: musical instruments, weather patterns, architectural elements, vehicles, household items
- Connect the analogy to specific observed behaviors or approaches

#### Retrospective-specific humor (optional but encouraged)

- Create a pun or light joke based on the specific work completed
- Reference technical challenges or breakthroughs in a playful way
- Keep it professional but memorable

#### Quality guidelines for icebreakers

**Personalization requirements**:
- Base every metaphor on specific observed behaviors during the collaboration
- Reference actual tools, approaches, or communication patterns used
- Avoid generic descriptions; make each icebreaker unique to this retrospective
- Connect creative elements to technical or process insights

**Evidence-based reasoning**:
- Cite specific examples from the work that support each metaphor
- Explain the connection between the creative analogy and real behaviors
- Use patterns observed across multiple interactions when possible

**Variety and freshness**:
- Check previous retrospectives to avoid repeating the same animals or metaphors
- Strive for creative diversity across the retrospective collection
- Use unexpected but appropriate comparisons that surprise and delight

**Tone and engagement**:
- Balance professional insight with playful creativity
- Make icebreakers memorable and shareable
- Focus on positive attributes while being authentic
- Encourage continued collaboration through engaging content

#### Integration with retrospective structure

These icebreakers should:
- Complement the technical analysis rather than replace it
- Provide emotional connection and relationship building
- Make retrospectives something people look forward to rather than endure
- Create memorable touchstones for future collaboration reference

### Step 6: Generate/Update Retrospective Document

#### If retrospective document exists (created during planning)

- Read existing document completely
- Update with comprehensive analysis and recommendations
- Preserve any existing content while adding new insights

#### If no retrospective document exists

##### CRITICAL: Document metadata generation

**NEVER manually create YAML frontmatter for retrospective documents.**

Generate metadata using the generate-metadata.sh script. Replace `<your-model-name>` with your actual model (e.g., "claude-opus-4.5", "gpt-4o"):
```bash
.github/ace-fca/scripts/generate-metadata.sh --agent-llm "<your-model-name>"
```

- Gather metadata using `.github/ace-fca/scripts/generate-metadata.sh`
- Create new retrospective document in `.github/ace-fca/retros/`
- Use filename with same numeric sequence as plan: `000N-topic.md`

#### Follow consistent structure

- Use YAML frontmatter with proper metadata
- Follow `.github/instructions/markdown.instructions.md` formatting
- Include cross-references to plan document and other related files
- Structure with clear sections for feedback analysis, recommendations, and icebreakers

#### Gather metadata for the retrospective document

- **CRITICAL**: Run the `.github/ace-fca/scripts/generate-metadata.sh` script to generate all metadata
- Use run_in_terminal: `.github/ace-fca/scripts/generate-metadata.sh --agent-llm "<your-model-name>"`
- Copy the script output as the foundation for your document
- Add the retrospective content below the frontmatter

### Step 7: Continuous Improvement Recommendations

#### Prompt evolution analysis

- Review effectiveness of research → plan → implement flow
- Identify friction points in ACE-FCA process
- Recommend specific improvements to prompt instructions
- Suggest new trigger phrases or workflow enhancements

#### Decision record creation (when applicable)

- Identify methodological improvements that should become decision records
- Recommend updates to ACE-FCA prompts or .github/instructions/
- Capture learnings that affect future development approaches

## Important Guidelines

1. **Follow Project Standards**:
   - **Primary**: `.github/copilot-instructions.md` - General coding guidelines and project conventions
   - **Supplementary**: `.github/instructions/*.instructions.md` - Domain-specific style guides (particularly markdown.instructions.md for retrospective documents)

2. **Focus on Learning and Improvement**:
   - Every retrospective should generate actionable insights
   - Balance constructive criticism with recognition of successes
   - Provide specific, implementable recommendations

2. **Maintain Engaging Tone**:
   - Use creative icebreakers to make retrospectives enjoyable
   - Balance technical analysis with relationship-building elements
   - Keep focus on collaborative improvement

3. **Be Systematic**:
   - Read all context files completely before analysis
   - Use established retrospective patterns consistently
   - Provide concrete evidence for all observations and recommendations

4. **Track Progress and Impact**:
   - Reference previous retrospectives when relevant
   - Note improvements in process over time
   - Suggest metrics for tracking retrospective effectiveness

## Retrospective Document Template Structure

```markdown
---
date: [Current date and time with timezone]
retrospective_for: "path/to/plan/document.md"
researcher: "GitHub Copilot"
git_commit: [Current commit hash]
branch: [Current branch name]
repository: [Repository name]
topic: "[Plan Topic] Retrospective"
tags: [retrospective, ace-fca, relevant-topic-tags]
status: complete
last_updated: [Current date in YYYY-MM-DD format]
last_updated_by: "GitHub Copilot"
---

# Retrospective: [Plan Topic]

**Date**: [Current date and time with timezone]
**Plan Document**: [Link to plan document]
**Git Commit**: [Current commit hash]
**Branch**: [Current branch name]

## User Feedback Analysis

### Feedback for Copilot
[Analysis of user's feedback about agent performance]

### Recommendations for Agent Improvement
[Specific improvements to ACE-FCA prompts and process]

### Feedback for User
[Analysis of user's self-reflection and suggestions for improvement]

## Technical Retrospective

### What went well
[Specific evidence from completed work]

### What to keep doing
[Patterns that should be repeated]

### What can be improved
[Concrete suggestions with reasoning]

### What was missing
[Gaps in process, tools, or approach]

## What the local review missed

CCR findings on this cycle's pull request and the local-gate gaps that let them through.

### CCR findings

Output of `.github/skills/ccr-loop/scripts/ccr-loop.sh capture <pr>`, or "No CCR findings this cycle."

```json
```

### Local-gate gaps and fixes
[For each finding, the local-review gap and the generalized check added, or why none was warranted]

## Creative Icebreakers

### Creative analogy
[Font, nut, relationship, situation, or object representing the collaborative dynamic]

## Lessons Learned

### For Future ACE-FCA Iterations
[Key insights for improving the methodology]

### Process Improvements
[Specific suggestions for workflow enhancements]

## References

- Plan document: `[path to plan]`
- Related retrospectives: `[links to related retros]`
- Decision records: `[any decisions captured during this work]`
```

## Success Criteria Guidelines

The retrospective should achieve:

1. **User feels heard and understood** in their feedback
2. **Concrete recommendations** for improving ACE-FCA process
3. **Identification of systemic improvements** to prompts/instructions
4. **Creative elements** that make retrospectives engaging rather than tedious
5. **Learning capture** that improves future development cycles

## Trigger Phrase Integration

During implementation or planning phases, users may use trigger phrases:
- "Add this to the retro..."
- "Retrospective note:"
- "For the retrospective:"
- "Remember for next time:"

When these phrases are detected, update the appropriate retrospective document with the observation.
