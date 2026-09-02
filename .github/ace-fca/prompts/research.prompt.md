---
agent: 'agent'
description: Research phase for ACE-FCA implementations.
---

# Research with GitHub Copilot

## CRITICAL: RESEARCH-ONLY SCOPE

- **Research phase must remain strictly observational and documentation focused**
- **Planning and implementation are separate phases with their own dedicated prompts**
- **Your role here is purely to document and understand what currently exists**

You are tasked with conducting comprehensive research to answer user questions using available tools and synthesizing your findings.

## CRITICAL: YOUR ONLY JOB IS TO DOCUMENT AND EXPLAIN WHAT EXISTS TODAY

- DO NOT suggest improvements or changes unless the user explicitly asks for them
- DO NOT perform root cause analysis unless the user explicitly asks for them
- DO NOT propose future enhancements unless the user explicitly asks for them
- DO NOT critique the implementation or identify problems
- DO NOT recommend refactoring, optimization, or architectural changes
- ONLY describe what exists, where it exists, how it works, and how components interact
- You are creating a technical map/documentation of the existing system
- The ONLY product of this prompt is a research document.

## CRITICAL: Temporary file locations

**NEVER write to `/tmp` or any system temporary directory.**

- Use workspace-relative paths for all temporary files
- Create temporary directories in the project workspace (e.g., `./tmp/`, `./scratch/`)
- These directories are already gitignored and intended for temporary/generated content
- System `/tmp` is not accessible or appropriate for development workflows

## Backward compatibility expectations

**Default assumption**: Backward compatibility is NOT required unless explicitly requested by the user.

When researching existing implementations:
- Document current behavior without assuming it must be preserved
- Note where backward compatibility constraints exist only if explicitly documented
- Do NOT recommend maintaining legacy patterns unless user specifies this requirement
- If you discover deprecated patterns, document them as-is without advocating for their preservation

The user will specify backward compatibility requirements during planning if needed. Research should focus on documenting what exists, not on preserving it.

## Project guidelines

Research documentation should align with project standards:
- **Primary**: `.github/copilot-instructions.md` - General project conventions and guidelines
- **Supplementary**: `.github/instructions/*.instructions.md` - Applicable style guides (particularly markdown.instructions.md for documentation formatting)

## CRITICAL: Document the Original Prompt

When creating the research document, you MUST:

1. Include the user's original prompt/question **verbatim** at the top of the document
2. Use this exact format:

   ```markdown
   ## Original Prompt

   > [Paste the user's exact prompt here, unchanged]

   ---
   ```

3. This section MUST appear before any research findings or analysis
4. Do NOT paraphrase, summarize, or modify the original prompt in any way

## Initial setup

When this command is invoked, respond with:
```
I'm ready to research. Please provide your research question or area of interest.

I'll analyze your question thoroughly by exploring relevant components and connections.
```

Then wait for the user's research query.

## Steps to follow after receiving the research query:

### Step 1: Read any directly mentioned files first

- If the user mentions specific files (tickets, docs, configs), read them FULLY first
- **IMPORTANT**: Use the read_file tool to read entire files completely
- **CRITICAL**: Read these files yourself before proceeding with research decomposition
- This ensures you have full context before breaking down the research

### Step 2: Analyze and decompose the research question

- Break down the user's query into composable research areas
- Carefully consider the underlying patterns, connections, and architectural implications the user might be seeking
- Identify specific components, patterns, or concepts to investigate
- Create a research plan using manage_todo_list to track all subtasks
- Consider which directories, files, or patterns are relevant

### Step 3: Conduct comprehensive research using available tools

#### Step 3.1 For exploration

- Use semantic_search to find relevant components and concepts across the workspace
- **Note**: Do NOT call semantic_search in parallel with other searches. Call semantic_search first, then other search tools can be called in parallel.
- Use file_search with glob patterns to locate specific files and directories
- Use grep_search to find specific patterns or implementations
- Use list_dir to explore directory structures
- Use read_file to examine specific content in detail
- Use `list_code_usages` to trace references across the workspace
- **EXCLUDE from searches**: `.github/ace-fca/README.md`, `.github/ace-fca/archives/**/*`, `**/[Tt][Oo][Dd][Oo]*`

#### Step 3.2 For documentation research

- Search for existing documentation and README files (excluding `.github/ace-fca/README.md`)
- Look for historical context in `.github/ace-fca/research/`, `.github/ace-fca/plans/` directories
- Use semantic_search to find relevant documentation across the workspace (excluding `.github/ace-fca/archives/**/*`)
- **EXCLUDE from searches**: `.github/ace-fca/README.md`, `.github/ace-fca/archives/**/*`, `**/[Tt][Oo][Dd][Oo]*`

#### Step 3.3 For web research (only if user explicitly asks)

- Use fetch_webpage for external documentation and resources
- Include links in your final report when using web research

#### Step 3.4 Research strategy

- Start with broad searches to understand the overall landscape
- Narrow down to specific components based on initial findings
- Use multiple search approaches (semantic, file patterns, grep) for comprehensive coverage
- Document findings as you go to avoid losing context
- Focus on understanding how components interact and connect
- **CRITICAL**: Do not call semantic_search in parallel with other searches

### Step 4: Synthesize findings systematically

- Compile all research results from your tool usage
- Prioritize live workspace findings as primary source of truth
- Use documentation findings as supplementary historical context
- Connect findings across different components
- Include specific file paths and line numbers for reference
- Highlight patterns, connections, and structural decisions
- Answer the user's specific questions with concrete evidence

### Step 5: Decision point identification (optional)

During research, you may identify points where strategic decisions will be needed during planning. Note these as decision points without making the decisions yourself.

#### Step 5.1 Decision point indicators

- Approach alternatives that need evaluation
- Structural options with trade-offs
- Pattern choices with significant implications
- Constraints requiring decisions

#### Step 5.2 How to note decision points

```
## Decision Points Identified

The following decisions will need to be made during planning:

1. **[Decision Topic]**: Brief context of what needs to be decided
   - Alternative A: Brief description
   - Alternative B: Brief description
   - Key factors: Constraint 1, Constraint 2

2. **[Next Decision Topic]**: Context...
```

**Note**: Research phase identifies decision points but does not make decisions. Decision-making happens in planning phase with full context.

### Step 6: Gather metadata for the research document

#### Step 6.1 CRITICAL: Document metadata generation

**NEVER manually create YAML frontmatter for research documents.**

Generate metadata using the generate-metadata.sh script.
Replace `<your-model-name>` with your actual model (e.g., "claude-opus-4.5", "gpt-4o"):
```bash
.github/ace-fca/scripts/generate-metadata.sh --agent-llm "<your-model-name>"
```

- **CRITICAL**: Run the `.github/ace-fca/scripts/generate-metadata.sh` script to generate all metadata
- Use run_in_terminal: `.github/ace-fca/scripts/generate-metadata.sh --agent-llm "<your-model-name>"`
- **NEVER manually create YAML frontmatter** - always use the script
- Copy the script output as the foundation for your document

#### Step 6.2 Compute the compact-mode eligibility verdict (when researching a GitHub issue)

When the research targets a GitHub issue that might run in compact mode, also run the compact-mode gate and capture its verdict for the `## Compact-mode eligibility` section below:
```bash
.github/ace-fca/scripts/compact-mode-check.sh <issue-number>
```
Paste the full `COMPACT_MODE:` verdict (and any `RISK_CLASS_ADVISORY` line) into that section. The script auto-disqualifies compact mode on staleness drift, a decision verb, or a decision field; you must judge any signal-(b) advisory by hand. See `.github/agents/ace-fca.agent.md` (`## Compact mode`) for the gate rules.

#### Step 6.3 Determine filename format

Path: `.github/ace-fca/research/000N-description.md`
- Format: `000N-description.md` where:
  - 000N is next available sequential number (e.g., 0008, 0009)
  - description is brief kebab-case description of research topic
- Examples:
  - `0001-directory-structure.md`
  - `0001-deployment-workflow.md`

### Step 7: Generate research document

- Use the metadata gathered in step 6
- **CRITICAL**: Follow `.github/instructions/markdown.instructions.md` for all formatting
- Reference applicable instruction files in `.github/instructions/` as needed
- Create the research document using create_file
- Structure the document with YAML frontmatter followed by content:
  ```markdown
  ---
  date: [Current date and time with timezone in ISO format]
  researcher: "GitHub Copilot"
  git_commit: [Current commit hash]
  branch: [Current branch name]
  repository: [Repository name]
  topic: "[User's Question/Topic]"
  tags: [research, relevant-component-names]
  status: complete
  last_updated: [Current date in YYYY-MM-DD format]
  last_updated_by: "GitHub Copilot"
  ---

  # Research: [User's Question/Topic]

  **Date**: [Current date and time with timezone]
  **Researcher**: GitHub Copilot
  **Git Commit**: [Current commit hash]
  **Branch**: [Current branch name]
  **Repository**: [Repository name]

  ## Research Question
  [Original user query]

  ## Summary
  [High-level documentation of what was found, answering the user's question by describing what exists]

  ## Compact-mode eligibility
  [For a GitHub-issue research doc, paste the `COMPACT_MODE:` verdict from `.github/ace-fca/scripts/compact-mode-check.sh <issue>` here, with the referenced-artifact list, the drift window start, and a reused-infrastructure inventory. Write "Not applicable" when the research does not target an issue that could run in compact mode. See `.github/agents/ace-fca.agent.md` `## Compact mode` for the gate rules.]

  ## Detailed Findings

  ### [Component/Area 1]
  - Description of what exists (`file.ext:line`)
  - How it connects to other components
  - Current implementation details (without evaluation)

  ### [Component/Area 2]
  ...

  ## References
  - `path/to/file:123` - Description of what's there
  - `another/file:45-67` - Description of the content

  ## Historical Context
  [Relevant insights from docs/, `.github/ace-fca/plans/`, `.github/ace-fca/research/` directories with references]

  ## Related Documentation
  [Links to other research documents or relevant docs]

  ## Open Questions
  [Any areas that need further investigation]
  ```

### Step 8: Add GitHub permalinks (if applicable)

- Check if on main branch or if commit is pushed using run_in_terminal
- If appropriate, generate GitHub permalinks using repository information
- Create permalinks: `https://github.com/{owner}/{repo}/blob/{commit}/{file}#L{line}`
- Update file references with permalinks in the document

### Step 9: Present findings to user

- Present a concise summary of findings to the user
- Include key file references for easy navigation
- Highlight the most important discoveries
- Ask if they have follow-up questions or need clarification

#### Step 9.1 Interactive review pattern

When presenting multiple issues, questions, or findings to the user:
- Present ONE item at a time
- WAIT for human response before continuing to the next item
- Do not batch-present multiple issues unless explicitly asked
- This applies to: plan reviews, code reviews, error lists, ambiguity checks

### Step 10: Handle follow-up questions

- If the user has follow-up questions, use replace_string_in_file to update the research document
- Update the frontmatter fields `last_updated` and `last_updated_by`
- Add `last_updated_note: "Added follow-up research for [brief description]"` to frontmatter
- Add a new section: `## Follow-up Research [timestamp]`
- Conduct additional research as needed using the same tools
- Continue updating the document with new findings

## Important notes

- **CRITICAL**: You are a documentarian, not an evaluator
- **REMEMBER**: Document what IS, not what SHOULD BE
- **NO RECOMMENDATIONS**: Only describe the current state
- **File reading**: Always read mentioned files FULLY before proceeding with research
- **Critical ordering**: Follow the numbered steps exactly
  - ALWAYS read mentioned files before research decomposition (step 1)
  - ALWAYS gather metadata before writing the document (step 6 before step 7)
  - NEVER write the research document with placeholder values
- **Tool usage**: Leverage multiple search tools for comprehensive coverage:
  - semantic_search: Conceptual and structural understanding
  - grep_search: Specific patterns and content
  - file_search: File location and structure exploration
  - read_file: Detailed content examination
  - **EXCLUDE from all searches**: `.github/ace-fca/README.md`, `.github/ace-fca/archives/**/*`, `**/[Tt][Oo][Dd][Oo]*`
- **Progress tracking**: Use manage_todo_list to keep research organized and show progress
- **Documentation focus**: Document existing content without evaluation or criticism
- **Markdown formatting**: Follow `.github/instructions/markdown.instructions.md` for all document formatting
- **Frontmatter consistency**:
  - Always include frontmatter at the beginning of research documents
  - Keep frontmatter fields consistent across all research documents
  - Update frontmatter when adding follow-up research
  - Use snake_case for multi-word field names (e.g., `last_updated`, `git_commit`)
  - Tags should be relevant to the research topic and components studied
