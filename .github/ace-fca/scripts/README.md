# ACE-FCA scripts

Automation scripts for managing ACE-FCA documents and workflows.

## compact-mode-check.sh

Computes an ACE-FCA compact-mode eligibility verdict for a GitHub issue. It parses referenced artifacts (code paths and `0NNN` plan references) from the issue, counts merged PRs that touched those artifacts since the issue was filed (staleness drift), and evaluates risk-class signals. It prints a `COMPACT_MODE: eligible|disqualified` verdict that belongs in the research doc's compact-mode subsection.

The verdict is deliberately conservative: any drift, decision verb (signal a), or decision field (signal c) disqualifies compact mode. Signal (b), a fuzzy "cites a metric-policy contract" heuristic, is printed as an advisory the human confirms rather than an automatic disqualifier.

### Usage

```bash
./compact-mode-check.sh <issue-number>
./compact-mode-check.sh --repo owner/repo --since 2026-08-23 <issue-number>
./compact-mode-check.sh --help
```

Requires an authenticated `gh`.

### Tests

Pure-function unit tests live in `compact-mode-check.bats` and make no network calls. Run them with:

```bash
make test-scripts
```

`make test-scripts` runs every `*.bats` file under this directory. It is local-only and is intentionally not part of `make review` (CI stays Go-only). It skips cleanly when `bats` is not installed; install `bats` via `script/bootstrap`.

## archive-documents.sh

Automated two-tier archival system for research, plan, and retrospective documents.

### Usage

**Preview mode** (default - shows what would be archived):
```bash
./archive-documents.sh
```

**Execute mode** (actually archives files):
```bash
./archive-documents.sh --execute
```

**Help**:
```bash
./archive-documents.sh --help
```

### Archival criteria

Files are archived when:
- NOT in the last 10 documents by sequential number

Files are kept when:
- In the last 10 by sequential number (e.g., 0084-0093)

### Behavior

The script:
- Extracts sequential numbers from filenames
- Identifies the top 10 by number in each category
- Adds `archived_date` field to frontmatter before moving
- Moves files to `.github/ace-fca/archives/{category}/`
- Reports move failures if any occur

## changed-files.sh

Lists the files changed on the current branch relative to a base branch (`git diff BASE...HEAD` against the merge-base). Used to scope the local `code-review.prompt.md` pass to just the committed changes on the branch.

### Usage

```bash
./changed-files.sh                       # all changed files vs. main
./changed-files.sh --base develop        # compare against a different base
./changed-files.sh -e go -e sh           # only .go and .sh files
./changed-files.sh --existing            # only files that still exist
./changed-files.sh --no-symlinks         # exclude symlinks
./changed-files.sh --help
```

Requires `git`. Run from within the repository.
