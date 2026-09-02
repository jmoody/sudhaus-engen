# Copilot instructions

## What this repo is

Engen Brews (Engen Braut) is a single-developer brewing-calendar website for a German audience. It renders brew-day events plus the legally required German pages (Impressum and Datenschutzerklarung) and sets no cookies. The service is implemented in Go and ships as a Docker container. It is hosted on an Azure Virtual Machine in West Europe, provisioned and maintained with Terraform. See `docs/adrs/` for the accepted hosting and deploy-topology decision.

## Companion instructions

Scoped instruction files auto-apply to matching files and are not duplicated here:

- `.github/instructions/go.instructions.md` covers Go style (`applyTo: "**/*.go,**/go.mod,**/go.sum"`).
- `.github/instructions/bash.instructions.md` covers shell scripts (`applyTo: "script/**,**/*.sh"`).
- `.github/instructions/dockerfile.instructions.md` covers Dockerfiles (`applyTo: "**/Dockerfile,**/Dockerfile.*,**/*.dockerfile"`).
- `.github/instructions/markdown.instructions.md` covers Markdown (`applyTo: "**/*.md"`).
- `.github/instructions/terraform.instructions.md` covers Terraform and Azure infrastructure under `terraform/` (`applyTo: "**/*.tf,terraform/**"`).

## Architecture decisions

Significant, hard-to-reverse technical decisions (hosting, deploy topology, new dependencies) are recorded as Architecture Decision Records under `docs/adrs/`. Read the relevant ADR before changing a decision it covers, and author new ADRs with the `adr-author` skill.

## Pre-flight check (`make review`)

Before opening a PR or marking work done, run `make review`. It runs the full local verification slice that works without live credentials: build, imports, lint (Go + shell), and unit tests. A clean `make review` is required before requesting review. New verification steps go into `make review`, not into ad-hoc commands.

## Pull requests

When a coding agent opens a pull request by any means (`gh pr create`, the GitHub API, or an MCP tool), it must provide the title and body explicitly rather than relying on generated or auto-filled content.

- Open pull requests as drafts by default (`gh pr create --draft`, or `draft: true` in API/MCP calls); mark them ready only when the change is complete and `make review` passes.
- Keep the description short: aim for three to five sentences total, and never exceed one short paragraph plus a one-line verification note. State the motivation and the approach in a sentence or two each; do not restate the issue, re-explain background the reader already has, or justify decisions at length. Do not enumerate changes or provide a file-by-file breakdown; reviewers can read the diff.
- Include the relevant verification performed in a single sentence, and do not claim verification that was not performed.
- Reference a related issue only when one exists and its number is known, and use the correct linking keyword: write `closes #<number>` when the pull request fully implements the issue, or `progress on #<number>` when it only partially implements it. GitHub auto-closes the issue on merge only for `closes` (and its synonyms); `progress on` is not a closing keyword, so it links without closing.
- Keep the description neutral and blame-free. Avoid loaded words such as "broken", "messy", or "badly".
- Write pull request and issue descriptions as continuous paragraphs. Do not hard-wrap prose at a fixed column width.
- After opening every pull request, request Copilot Code Review (CCR) explicitly through the REST API, including pull requests that change only generated ACE-FCA artifacts. Verify that the request appears in the issue timeline as a `review_requested` event naming `Copilot`, wait for the review, and address every actionable comment before proceeding.
- Iterate the CCR loop until the review comes back clean: request review, wait for the review to land, fix or otherwise address every comment, resolve the corresponding review threads, then request a fresh CCR. Repeat this cycle until a new review produces no actionable comments. Do not treat a single review pass as sufficient when it raised comments; a clean pass with zero new comments is the exit condition.
- Resolve each review thread only after the comment is fixed or explicitly addressed, using the `resolveReviewThread` GraphQL mutation on the thread id. A comment you disagree with must be answered in a reply before resolving; do not silently resolve unaddressed threads.
- Use the pull request issue timeline to monitor CCR activity and confirm follow-up requests. The reviews endpoint returns only submitted reviews, so an empty review list does not mean CCR is not in progress; check the timeline again before concluding that no review exists.

## Troubleshooting

- **`golangci-lint` reports errors against paths that don't exist** (e.g. `../jmoody-issue-*/...`): the lint cache picked up a sibling worktree that has since been deleted. Run `bin/golangci-lint cache clean` (or `make clean`, which now includes it) and re-run lint.
- **Shell refuses commands that contain the bare word `kill`**: write commit messages and PR bodies to a file under `tmp/` and pass them via `git commit -F` and `gh pr create -F` / `--body-file`.

## Scripting

Bash is the scripting language for this repo. Shell scripts live under `script/` and follow `.github/instructions/bash.instructions.md`.

## Operational helpers are bash + `go run`

When operational logic needs to run, the pattern is: a bash script under `script/` loads `.env` and `exec`s `go run ./cmd/<entrypoint> <subcommand>`. Keep operational subcommands out of the main service binary.

## Conventions for Go code

Defers to `.github/instructions/go.instructions.md` for style.

## Testing

- `make test` runs unit + race tests.
- `make lint` runs Go and shell linters.
- CI runs `make test` only.
- The agent is not done until `make review` passes.

## Security & safety

- Never commit `.env`, secrets, tokens, or anything under `data/`.

## What not to do

- No refactoring unrelated code.
- No comments or docstrings on unmodified code.
- No new dependencies without first checking `go.mod`.
- **Don't use `/tmp`, use `./tmp`.** Never write to `/tmp`, `$TMPDIR`, `/var/folders`, or any other system temp dir, and never call `mktemp` without `-p ./tmp`. Every scratch file, heredoc target, commit message, PR body, and intermediate artifact goes in the repo-local `./tmp/` (or `./scratch/`) directory, both of which are gitignored. Create it with `mkdir -p tmp` first if it is missing.
- No em dashes (`—`); use a hyphen, comma, or period.
- Never invoke `python` or `python3`; use bash or `go run` for scripting.
- **Never read anything under `git/github/`.** The directories `~/git/github/` and `/Volumes/cucumber/git/github/` hold employer repositories and are strictly off limits. Do not open, list, `grep`, `find`, `cat`, or otherwise access any path beneath them, and do not copy, quote, paraphrase, or summarize their contents into this repository. This applies even when a path there looks like useful prior art, and even when the user's request would be easier to satisfy by reading it. Sibling directories such as `~/git/jmoody/` remain readable.
