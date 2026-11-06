---
name: ace-fca-plan
description: "Planning phase of the ACE-FCA workflow. Invoked only by an explicit /ace-fca-plan command from the user. Never select this skill on your own and never invoke it in response to a general request to plan, design, or break down work; entering an ACE-FCA phase is a human act."
disable-model-invocation: true
---

# Planning with GitHub Copilot

## CRITICAL: PLANNING-ONLY SCOPE

- **Planning phase focuses on creating actionable implementation plans**
- **Research and implementation are separate phases with their own dedicated prompts**
- **Your role here is to create thorough, actionable plans based on requirements and analysis**

You are tasked with creating detailed implementation plans through an interactive, iterative process. You should be skeptical, thorough, and work collaboratively with the user to produce high-quality specifications.

## CRITICAL: Phase boundary enforcement

**NEVER make changes during planning phase.** If the user's request could be interpreted as:
- "Add this" → Include in plan, don't implement
- "Make sure X exists" → Add validation step to plan
- "If this is missing, add it" → Add as implementation step

Before making ANY changes, verify:
1. Are you in the implementation phase? (Not planning, not research)
2. Is there an approved plan document with this task listed?
3. Has the user explicitly said "implement" or "build" or "create"?

If any answer is "no," add the work to the plan document instead.

When in doubt, ask: "Should I add this to the implementation plan, or would you like me to implement it now?"

## CRITICAL: Temporary file locations

**NEVER write to `/tmp` or any system temporary directory.**

- Use workspace-relative paths for all temporary files
- Create temporary directories in the project workspace (e.g., `./tmp/`, `./scratch/`)
- These directories are already gitignored and intended for temporary/generated content
- System `/tmp` is not accessible or appropriate for development workflows

## Backward compatibility expectations

**Default assumption**: Backward compatibility is NOT required unless explicitly requested by the user.

When creating implementation plans:
- Plan for clean replacements rather than maintaining legacy patterns
- Do NOT plan migration paths or compatibility layers unless user explicitly requests them
- When replacing content, plan to DELETE old material rather than deprecate it

**Recognition pattern for backward compatibility requirements**:
- User explicitly says "maintain backward compatibility"
- User mentions "migration path" or "gradual rollout"
- External consumers depend on the interface being changed

If none of these conditions exist, plan for clean replacement. When uncertain, ask: "Should I plan for backward compatibility, or is a clean replacement preferred?"

## CRITICAL: Document the Original Prompt

When creating the planning document, you MUST:

1. Include the user's original prompt/question **verbatim** at the top of the document
2. Use this exact format:

   ```markdown
   ## Original Prompt

   > [Paste the user's exact prompt here, unchanged]

   ---
   ```

3. This section MUST appear before any planning content or analysis
4. Do NOT paraphrase, summarize, or modify the original prompt in any way

## The plan document schema (CLOSED)

A plan contains these sections, in this order, and **nothing else**. The schema is closed: no section outside it is permitted, however useful it seems while writing. Clutter is what a plan accumulates when its shape is left to the author, and no amount of cleanup afterwards is as effective as a shape that has no room for it.

| Section                    | Holds                                                     | Required |
| -------------------------- | --------------------------------------------------------- | -------- |
| frontmatter                | metadata, research link, status                           | yes      |
| `## Original Prompt`       | the originating prompt, verbatim                          | yes      |
| `## Goal`                  | what the plan delivers, one or two sentences              | yes      |
| `## Settled decisions`     | decisions as current truth, no rationale, no alternatives | yes      |
| `## Starting state`        | verified facts and file paths the plan builds on          | yes      |
| `## Out of scope`          | explicit non-goals                                        | yes      |
| `## Implementation phases` | `### Phase N` with steps and success criteria             | yes      |
| `## Verification`          | how completion is proven                                  | yes      |
| `## Deliverable content`   | verbatim payload when the deliverable is text             | optional |
| `## References`            | links only, no prose                                      | yes      |

Three rules govern the content:

- **`## Settled decisions` records outcomes, never the path to them.** Write the decision as current truth. Rejected alternatives, pros and cons lists, comparisons, and the rationale for choices already made do not appear. If a reader needs to know why, the research document is where that lives, and the plan does not route material there as a cleanup step.
- **`## Starting state` holds verified facts only.** Every file path, line number, and count in it was produced by a search that was actually run, not recalled.
- **One fact, one place.** A fact stated in two sections becomes two facts that disagree after the first edit.

### Plan status values

The frontmatter `status` field takes exactly one of three values:

| Value      | Meaning                                                                                   |
| ---------- | ----------------------------------------------------------------------------------------- |
| `draft`    | Being written or revised. Open questions may remain. Not ready to implement.              |
| `ready`    | Complete, verified by Step 8's sweep, and approved by the user. Implementation may begin. |
| `complete` | Implemented and verified. The plan is now a historical record and is not rewritten.       |

## Initial Response

When this command is invoked:

1. **Check if parameters were provided**:
   - If a file path or ticket reference was provided as a parameter, skip the default message
   - Immediately read any provided files FULLY
   - Begin the research process

2. **If no parameters provided**, respond with:
```
I'll help you create a detailed implementation plan. Let me start by understanding what we're building.

Please provide:
1. The research document in .github/ace-fca/research
2. Any relevant context, constraints, or specific requirements
3. Links to related research or previous implementations

I'll analyze this information and work with you to create a comprehensive plan.
```

Then wait for the user's input.

## Process Steps

### Step 1: Context Gathering & Initial Analysis

#### Step 1.1 Read all mentioned files immediately and FULLY

- Ticket files (e.g., `.github/ace-fca/research/0001-topic.md`)
- Research documents
- Related implementation plans
- Any data files mentioned
- **IMPORTANT**: Use the `view` tool WITHOUT a view_range parameter to read entire files
- **CRITICAL**: DO NOT use the `task` tool before reading these files yourself in the main context
- **NEVER** read files partially - if a file is mentioned, read it completely

#### Step 1.2 Conduct initial research to gather context

Before asking the user any questions, use available tools to research in parallel:

##### For exploration

- Use `semantic_code_search` to find all files related to the ticket/task
- **Note**: Do NOT call `semantic_code_search` in parallel with other searches. Call `semantic_code_search` first, then other search tools can be called in parallel.
- Use `glob` to locate relevant files and configs
- Use `grep` to find specific patterns or implementations
- Use `glob` to explore directory structures and identify focus areas
- Use `grep` narrowed by a file glob to find all references to items being modified
- **EXCLUDE from searches**: `.github/ace-fca/README.md`, `.github/ace-fca/archives/**/*`, `**/[Tt][Oo][Dd][Oo]*`

##### For documentation research

- Search existing documentation in README files (excluding `.github/ace-fca/README.md`)
- Look for historical context in `.github/ace-fca/plans/`, `.github/ace-fca/research/` directories
- Use `semantic_code_search` to find relevant documentation across the workspace (excluding `.github/ace-fca/archives/**/*`)
- **EXCLUDE from searches**: `.github/ace-fca/README.md`, `.github/ace-fca/archives/**/*`, `**/[Tt][Oo][Dd][Oo]*`

These tools will help you:
- Find relevant files and configs
- Identify the specific areas to focus on
- Trace relationships and dependencies
- Discover patterns and conventions to follow

#### Step 1.3 Read all files identified by research

- After using search tools, read ALL files they identified as relevant
- Use `view` to examine them FULLY into the main context
- This ensures you have complete understanding before proceeding

#### Step 1.4 Analyze and verify understanding

- Cross-reference the requirements with actual content
- Identify any discrepancies or misunderstandings
- Note assumptions that need verification
- Determine true scope based on reality

#### Step 1.5 Present informed understanding and focused questions

```
Based on the requirements and my research, I understand we need to [accurate summary].

I've found that:
- [Current state detail with file:line reference]
- [Relevant pattern or constraint discovered]
- [Potential complexity or edge case identified]

Questions that my research couldn't answer:
- [Specific question that requires human judgment]
- [Clarification needed]
- [Design preference that affects implementation]
```

Only ask questions that you genuinely cannot answer through investigation.

### Step 2: Research & Discovery

After getting initial clarifications:

#### Step 2.1 If the user corrects any misunderstanding

- DO NOT just accept the correction
- Use search tools again to verify the correct information
- Use `view` to examine the specific files and directories they mention
- Only proceed once you've verified the facts yourself

#### Step 2.2 Create a research todo list

using the `sql` tool's `todos` table to track exploration tasks

#### Step 2.3 Conduct comprehensive research using available tools

##### For deeper investigation

- Use `semantic_code_search` to find more specific files and components
- Use `grep` to understand details and patterns
- Use `glob` to locate similar work you can model after
- Use `glob` to explore relevant directory structures
- **EXCLUDE from searches**: `.github/ace-fca/README.md`, `.github/ace-fca/archives/**/*`, `**/[Tt][Oo][Dd][Oo]*`

##### For documentation research

- Search existing documentation in `.github/ace-fca/plans/`, `.github/ace-fca/research/` directories (excluding `.github/ace-fca/README.md` and `.github/ace-fca/archives/**/*`)
- Use `semantic_code_search` to find relevant historical context and decisions (excluding `.github/ace-fca/archives/**/*`)
- **EXCLUDE from searches**: `.github/ace-fca/README.md`, `.github/ace-fca/archives/**/*`, `**/[Tt][Oo][Dd][Oo]*`

##### Research strategy

- Start with broad searches to understand the overall landscape
- Narrow down to specific components based on initial findings
- Use multiple search approaches for comprehensive coverage
- Read identified files completely to understand patterns and conventions
- Look for integration points and dependencies
- Find examples that demonstrate current patterns
- **CRITICAL**: Do not call `semantic_code_search` in parallel with other searches

#### Step 2.4 Present findings and design options

```
Based on my research, here's what I found:

**Current State:**
- [Key discovery about existing content]
- [Pattern or convention to follow]

**Design Options:**
1. [Option A] - [pros/cons]
2. [Option B] - [pros/cons]

**Open Questions:**
- [Uncertainty]
- [Design decision needed]

Which approach aligns best with your vision?
```

### Step 3: Phasing development

Once aligned on approach:

#### Step 3.1 Propose the phasing

The plan's sections are fixed by the closed schema above and are not up for discussion. What needs agreement is the phasing, so propose only that:

```
Here's my proposed phasing:

1. [Phase name] - [what it accomplishes]
2. [Phase name] - [what it accomplishes]
3. [Phase name] - [what it accomplishes]

Does this phasing make sense? Should I adjust the order or granularity?
```

#### Step 3.2 Get feedback on the phasing

before writing details

### Step 4: Detailed Plan Writing

#### Step 4.1 CRITICAL: Document metadata generation

**NEVER manually create YAML frontmatter for plan documents.**

Generate metadata using the generate-metadata.sh script. Replace `<your-model-name>` with your actual model (e.g., "claude-opus-4.5", "gpt-4o"):
```bash
.github/ace-fca/scripts/generate-metadata.sh --agent-llm "<your-model-name>"
```

After phasing approval:

#### Step 4.2 Write the plan

to `.github/ace-fca/plans/000N-description.md`
- **CRITICAL**: The plan follows the closed schema defined above. Write those sections and no others. Set `status: draft` until Step 8's sweep and user approval move it to `ready`.
- Format: `000N-description.md` where:
  - 000N is extracted from the provided research document path (e.g., if research is `0014-feature.md`, plan uses `0014`)
  - If no research document provided, calculate next available sequential number as fallback
  - description is brief kebab-case description of plan topic
- Examples:
  - `0001-update-documentation.md`
  - `0002-restructure-configs.md`
- **CRITICAL**: Follow `.github/instructions/markdown.instructions.md` for all formatting

#### Step 4.3 Follow the general coordination instructions in `.github/copilot-instructions.md`

#### Step 4.4 Follow applicable instructions as needed

- Reference `.github/instructions/*.instructions.md` for domain-specific formatting

#### Step 4.5 Gather metadata for the plan document

- **CRITICAL**: Run the `.github/ace-fca/scripts/generate-metadata.sh` script to generate all metadata
- Use `bash`: `.github/ace-fca/scripts/generate-metadata.sh --agent-llm "<your-model-name>"`
- Copy the script output as the foundation for your document
- Add the plan content below the frontmatter

**Plan template should include for each phase**:
```markdown
### Phase N: [Description]

#### Implementation steps
1. [Step description]
2. [Step description]
3. [Step description]

#### Success criteria
- [ ] [Verifiable criterion]
- [ ] [Verifiable criterion]
```

### Step 5: Create Retrospective Document

**NEVER manually create YAML frontmatter for retrospective documents.**

Generate metadata using the generate-metadata.sh script. Replace `<your-model-name>` with your actual model (e.g., "claude-opus-4.5", "gpt-4o"):
```bash
.github/ace-fca/scripts/generate-metadata.sh --agent-llm "<your-model-name>"
```

After writing the plan and before presenting to user:

#### Step 5.1 Create matching retrospective document

- Path: `.github/ace-fca/retros/000N-description.md` (using same sequence number from research document)
- Number inheritance flow: Research → Plan → Retrospective (all use same 000N)
- Use the retrospective template structure
- Include frontmatter with plan reference
- Add placeholder sections for future completion

#### Step 5.2 Use the retrospective template

- Copy from `.github/ace-fca/templates/retrospective-template.md`
- Fill in the frontmatter with current context (date, git commit, branch, etc.)
- Set status to "in-progress"
- Add note that it will be completed after implementation
- Reference the corresponding plan document

#### Step 5.3 Inform user of retrospective creation

```
I've created the implementation plan and also set up a retrospective document:
- Plan: `.github/ace-fca/plans/000N-description.md`
- Retrospective: `.github/ace-fca/retros/000N-description.md`

The retrospective document is ready to collect feedback throughout implementation. Use trigger phrases like "add this to the retro..." during implementation to capture observations in real-time.
```

### Step 6: Present and Review

#### Step 6.1 Present the draft plan location

```
I've created the initial implementation plan at:
`.github/ace-fca/plans/000N-description.md`

Please review it and let me know:
- Are the phases properly scoped?
- Are the success criteria specific enough?
- Any details that need adjustment?
- Missing edge cases or considerations?
```

#### Step 6.2 Interactive review pattern

When presenting multiple issues, questions, or findings to the user:
- Present ONE item at a time
- WAIT for human response before continuing to the next item
- Do not batch-present multiple issues unless explicitly asked

#### Step 6.3 Iterate based on feedback

- be ready to:
- Add missing phases
- Adjust approach
- Clarify success criteria
- Add/remove scope items
- Use `edit` to update the plan based on feedback

#### Step 6.4 Continue refining

until the user is satisfied

### Step 7: Plan ambiguity review (INTERACTIVE)

Review the plan for implementation readiness. Present findings ONE AT A TIME and WAIT for human response before continuing.

**Check for**:
1. Open questions requiring answers
2. Ambiguities in requirements or approach
3. Gaps in understanding

**Process**:
1. Identify first issue
2. Present to human with location, issue description, and suggested fix

#### Step 7.1 STOP and WAIT for human response

3. Only after human responds, proceed to next issue
4. Repeat until all issues reviewed

**Output**: Add findings to retrospective under "ACE-FCA Improvements" → "Planning Prompt".

**Skip condition**: For trivial changes (<50 lines, single file), abbreviated review is acceptable.

### Step 8: Pre-finalisation verification sweep (MANDATORY)

This runs last, on the text that will ship. Step 7 rewrites the plan, so verifying before it would verify a draft that no longer exists.

Before the plan can move from `draft` to `ready`, it must survive a mechanical verification sweep. This step replaces the judgement-based self-review that preceded it. A self-review by the authoring session is the failure mode this step exists to avoid: the session that wrote the plan already believes it, so it re-reads instead of re-checking.

**Delegate the sweep to a fresh subagent.** Use the `task` tool with a cold-read agent that has not seen the planning conversation. Give it the plan path and the three checks below. Its findings must be resolved before the plan reaches `ready`.

**Check 1: every changed value is enumerated everywhere it lives.**

For every value the plan changes (a path, a filename, a basename, a constant, a heading, a command, a tool name), search the repository for every file that holds it, and confirm the plan names each one. State the search that was run and its output.

The failure this catches is a plan that lists three reference sites when the repository holds six. References that cite a **basename** rather than a path are invisible to a search for the directory, so search both forms:

```bash
grep -rn "path/to/the-file.md" --include=*.md .
grep -rn "the-file.md" --include=*.md .
```

**Check 2: no fact is stated in more than one place.**

Compare the plan's sections against each other. A fact that appears in two sections will drift when one is edited: a count, a file list, or a phase description restated in both a step and its success criterion becomes two facts that disagree. Collapse each duplicate to a single authoritative site and reference it from the other.

**Check 3: every number in the plan was counted, not estimated.**

For every count the plan states, re-run the search that produces it and compare. Miscounts are routine and survive proofreading, because a restated number reads as already verified.

```bash
grep -rnE "pattern" --include=*.md . | wc -l
```

**Resolution.** Present the subagent's findings ONE AT A TIME and WAIT for a human response on each. Record a summary in the retrospective under "ACE-FCA Improvements" → "Planning Prompt", answering why planning missed each finding.

**Running a verification command is the step; asserting its result is not.** Every search named here is executed against the working tree and its output read. A success criterion the plan has never run is an assumption with a checkbox next to it.

## Important guidelines

#### Be skeptical

- Question vague requirements
- Identify potential issues early
- Ask "why" and "what about"
- Don't assume - verify

#### Be interactive

- Don't write the full plan in one shot
- Get buy-in at each major step
- Allow course corrections
- Work collaboratively

#### Be thorough

- Read all context files COMPLETELY before planning
- Research actual patterns using available search tools
- Include specific file paths and line numbers
- Write measurable success criteria

#### Be practical

- Focus on incremental, verifiable changes
- Consider rollback scenarios
- Think about edge cases
- Include "what we're NOT doing"

#### Track progress

- Use the `sql` tool's `todos` table to track planning tasks
- Update todos as you complete research
- Mark planning tasks complete when done

#### No open questions in final plan

- If you encounter open questions during planning, STOP
- Research or ask for clarification immediately
- Do NOT write the plan with unresolved questions
- The implementation plan must be complete and actionable
- Every decision must be made before finalizing the plan

#### Scope control validation

- **CRITICAL**: Detect and flag potential scope creep during planning
- Validate plan scope before presenting to user
- Display clear warnings when scope expansion indicators detected

##### Scope creep indicators to flag

- Hypothetical feature references ("when we", "future", "might need", "eventually")
- Implementation beyond immediate requirements stated in research/requirements
- Creating stubs or placeholders for items not in current scope
- Building generic frameworks instead of specific solutions
- Adding features because "we might need them later"

##### When scope creep detected

```
:warning: SCOPE EXPANSION DETECTED :warning:

The current plan includes the following scope expansion indicators:

1. [Specific indicator found]
2. [Another indicator]

Recommendation: Focus on minimal viable solution first. Additional work can be separate plans.

Should I:
A) Revise the plan to focus on immediate requirements only
B) Keep current scope (explain why this complexity is necessary now)
C) Split into multiple smaller plans
```

**Scope Validation Checklist** - this is a **gate, not a document section**. Verify each item before presenting the plan. The checklist is something the plan passes through, and its output never appears in the plan: a plan does not contain a list of ticked scope boxes, because the schema has no section for one and a passed gate leaves no residue.

- [ ] Every new item has clear justification in current requirements
- [ ] No hypothetical "future needs" driving current implementation
- [ ] No premature optimization or over-engineering
- [ ] Each phase delivers concrete, immediately useful results
- [ ] Complexity matches actual requirements (not anticipated future ones)

## Decision Record Creation

During planning conversations, you may encounter strategic decisions that should be captured for future reference.

**Trigger Phrases that Create Decision Records**:
- "add that as a decision record"
- "capture this decision"
- "document this choice"
- "create a decision record for this"

**When Triggered**:
1. **Immediately create** decision record in `.github/ace-fca/decision-records/`
2. **Use sequential numbering**: Find highest existing number and increment (000-xxx.md, 001-xxx.md, etc.)
3. **Follow template**: Use `.github/ace-fca/templates/decision-record-template.md` format
4. **Reference current context**: Link to current research/plan documents being discussed
5. **Focus on strategic**: Only capture decisions with significant impact

**Decision Record Scope** (Strategic ONLY):
- :white_check_mark: Approach choices (methodology, workflow)
- :white_check_mark: Structural decisions (organization, conventions)
- :white_check_mark: Process methodology choices (development workflows)
- :x: Style preferences (naming conventions)
- :x: Minor organizational details
- :x: Trivial selections

**Integration Notes**:
- Decision records are created **in addition to** normal planning conversation, not instead of it
- Trigger phrases work during **any phase** where decisions are made
- **No disruption** to current ACE-FCA workflow - this is purely additive capability

## Research Best Practices

When conducting research for planning:

#### Use multiple search approaches

for comprehensive coverage

#### Be systematic

in your exploration:
- Start with `semantic_code_search` for broad understanding
- Use `glob` for specific file patterns
- Use `grep` for content details
- Use `view` to examine content completely
- **EXCLUDE from searches**: `.github/ace-fca/README.md`, `.github/ace-fca/archives/**/*`, `**/[Tt][Oo][Dd][Oo]*`

#### Document findings

as you discover them using the `sql` tool's `todos` table

#### Focus on relevant areas

- For documentation changes: focus on `docs/`, `README.md` files
- For configuration: focus on config files, environment files
- For scripts: focus on `script/`, `.github/ace-fca/scripts/`
- **EXCLUDE from searches**: `.github/ace-fca/README.md`, `.github/ace-fca/archives/**/*`, `**/[Tt][Oo][Dd][Oo]*`

#### Look for existing patterns

- Similar work or existing conventions
- Naming patterns
- Structural patterns

#### Verify your understanding

- Cross-reference multiple files
- Look for integration points and dependencies

#### Be specific about file references

- Include full file paths
- Reference specific line numbers when possible
- Note key patterns discovered
