# Decision records in ACE-FCA methodology

## Overview

Decision records capture architectural and strategic decisions made during the ACE-FCA research → plan → implement workflow. They provide durable documentation of "why" decisions were made, linked back to their originating research and plan documents.

During planning and implementation phases, use these phrases to automatically create decision records:

- **"add that as a decision record"** - Captures the preceding decision discussion
- **"capture this decision"** - Documents the current architectural choice
- **"document this choice"** - Records the strategic decision being made
- **"create a decision record for this"** - Explicitly requests decision record creation

When these phrases are detected, the system will immediately create a decision record using the `.github/ace-fca/templates/decision-record-template.md` format.

## What qualifies as a decision record

### Architectural/strategic decisions (CAPTURE):
- Technology stack choices (Azure AI Foundry vs OpenAI API)
- Infrastructure approach decisions (provisioned vs serverless)
- Data architecture patterns (validation vs sanitization separation)
- Security model selections (authentication approach)
- Process methodology choices (ACE-FCA adoption)

### Tactical implementation details (DON'T CAPTURE):
- Code style preferences (variable naming conventions)
- Library selection for common tasks (testify vs other test frameworks)
- File organization choices (where to put utility functions)
- Performance optimizations (unless they change architecture)

## Integration with ACE-FCA workflow

### Research phase
- Research documents identify decision points but don't make decisions
- Research phase is purely investigative with no decision record creation
- Note when architectural choices are needed: "This requires a decision about..."

### Planning phase
- Plans make architectural decisions based on research findings
- Use trigger phrases to capture significant decisions
- Decision records created reference plan documents and any relevant existing documentation

### Implementation phase
- Implementation may reveal additional architectural decisions needed