# Issue tracker: GitHub

Issues and specs for this repo live as GitHub issues. Use the `gh` CLI for all operations.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`.
- **Read an issue**: `gh issue view <number> --json number,title,body,labels,comments`.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments`.
- **Make a sub-issue**: `gh issue create --parent <parent> ...`, or `gh issue edit <parent> --add-sub-issue <child>`.
- **Add a blocker**: `gh issue create --blocked-by <blocker> ...`, or `gh issue edit <child> --add-blocked-by <blocker>`. Use native issue dependencies.
- **Count open blockers**: `gh api 'repos/{owner}/{repo}/issues/<number>' --jq .issue_dependencies_summary.blocked_by`. A count of zero means the issue is unblocked.
- **Comment on an issue**: `gh issue comment <number> --body "..."`.
- **Apply / remove labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`.
- **Close**: explain the resolution in a comment, then run `gh issue close <number>`.

Infer the repo from `git remote -v`; `gh` does this automatically when run inside a clone. File issues only in the user's own repository; verify the target with `gh repo view --json nameWithOwner` if it is unclear.

## Pull requests as a triage surface

**PRs as a request surface: no.** Set this to `yes` only if this repo treats external PRs as feature requests.

When enabled, external PRs are those whose author is not an owner, member, or collaborator. Use the `gh pr` equivalents to read, comment on, label, and close them.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Read it with `gh issue view`.

## Wayfinding operations

- **Map**: an issue labelled `wayfinder:map`. Create the label if it is missing.
- **Child ticket**: a sub-issue of the map labelled `wayfinder:<type>`, where type is `research`, `prototype`, `grilling`, or `task`. Create the label if it is missing.
- **Blocking**: use the native issue dependencies described above.
- **Frontier**: list open children with `gh issue view <map> --json subIssues --jq '[.subIssues.nodes[] | select(.state == "OPEN") | .number]'`. For each child, check `gh issue view <child> --json assignees` and its open blocker count; the first unassigned child with no open blockers is the frontier ticket.
- **Claim**: `gh issue edit <child> --add-assignee @me` before starting work.
- **Resolve**: comment with the answer, close the child issue, then append a context pointer to the map's Decisions-so-far.
