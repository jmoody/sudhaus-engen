---
name: ccr-loop
description: "Run the iterative Copilot Code Review (CCR) loop on a pull request: request review, wait for it to land, address every comment, resolve the threads, then request a fresh review, repeating until a review returns no actionable comments. Use when asked to get CCR, resolve CCR comments, or drive a PR to a clean review."
license: MIT
---

# Iterative Copilot Code Review loop

Drive a pull request to a clean Copilot Code Review. CCR is not a single pass: each review can raise comments, and fixing them can surface new ones. The loop is **request -> wait -> address -> resolve -> re-request**, repeated until a review comes back with no actionable comments. A clean pass with zero new comments is the only exit condition.

This skill encodes the mechanical GitHub steps (requesting the review, confirming it on the timeline, waiting for the next review to land, listing unresolved threads, capturing every thread for the retrospective, replying, and resolving) in `scripts/ccr-loop.sh`. The judgment steps (actually fixing or answering each comment) stay with the agent.

The canonical location of this skill is `.github/ace-fca/skills/ccr-loop`; it is an ACE-FCA workflow artifact surfaced under `.github/skills/ccr-loop` via a directory symlink so the skills loader discovers it. Edit the files under `.github/ace-fca/skills/ccr-loop`.

This skill follows the Pull requests section of `.github/copilot-instructions.md`, which is the source of truth for CCR policy in this repo.

## When to use

Use this skill whenever the user asks to request Copilot Code Review, resolve CCR comments, or iterate a PR until the review is clean. It assumes an open pull request whose head branch is already pushed.

## Requirements

- `gh` authenticated for the repository. The script auto-detects `owner/repo` via `gh repo view`.
- Do not use `gh pr edit --add-reviewer Copilot`; it needs `read:org` scope the agent token lacks. The script uses the REST `requested_reviewers` endpoint instead.

## The loop

Run these steps from the repository, substituting the PR number for `<pr>`.

1. **Request and wait atomically** with `review`, which snapshots the baseline before requesting so a fast review cannot be missed:

   ```bash
   .github/skills/ccr-loop/scripts/ccr-loop.sh review <pr>
   ```

   It captures the current latest CCR review time, requests CCR, confirms the `review_requested` timeline event naming `Copilot`, then blocks until a strictly newer review lands and prints each unresolved CCR thread as a JSON line: `{id, path, line, body}`. Accepts `--timeout <seconds>` (default 900) and `--interval <seconds>` (default 30). If there are no unresolved threads, it reports the loop is complete.

   To drive the steps by hand instead, capture the baseline **before** requesting, then wait against it, so a review that lands between the two calls is not adopted as the baseline and ignored:

   ```bash
   since="$(.github/skills/ccr-loop/scripts/ccr-loop.sh latest <pr>)"
   .github/skills/ccr-loop/scripts/ccr-loop.sh request <pr>
   .github/skills/ccr-loop/scripts/ccr-loop.sh wait <pr> --since "$since"
   ```

2. **Address** every comment in the working tree. Fix the code, or, for a comment you disagree with, prepare a reply that explains the decision. Never silently resolve an unaddressed thread. Commit and push fixes locally (never through the GitHub API, which skips the `make review` gate).

3. **Resolve** each thread once its comment is fixed or answered. Reply first when you are explaining rather than fixing:

   ```bash
   .github/skills/ccr-loop/scripts/ccr-loop.sh reply <thread-id> "Explanation of how this was addressed."
   .github/skills/ccr-loop/scripts/ccr-loop.sh resolve <thread-id>
   ```

4. **Re-run `review`** and repeat from step 1. Continue until it reports no unresolved threads.

## Helper commands

```text
ccr-loop.sh review <pr> [--timeout N] [--interval N]
                                         Capture baseline, request CCR, wait for the next review, list threads.
ccr-loop.sh request <pr>                 Request CCR and verify the timeline event.
ccr-loop.sh latest <pr>                  Print the submitted_at of the latest CCR review.
ccr-loop.sh wait <pr> [--since TS] [--timeout N] [--interval N]
                                         Block until a newer CCR review lands, then list unresolved threads.
ccr-loop.sh threads <pr>                 List unresolved CCR review threads without waiting.
ccr-loop.sh capture <pr>                 List all CCR review threads (resolved and unresolved) for retrospective capture.
ccr-loop.sh reply <thread-id> <message>  Reply to a review thread.
ccr-loop.sh resolve <thread-id>          Resolve a review thread.
```

## Notes

- Verify progress against the issue timeline, not `requested_reviewers`; that array can stay empty on a request that succeeded and reads as a false negative.
- The reviews endpoint lists only submitted reviews, so an empty list can mean a review is still in progress. `wait` polls until a new one is submitted.
- CCR is matched by the bot login (`copilot-pull-request-reviewer[bot]` in REST, `copilot-pull-request-reviewer` in GraphQL); human review threads are ignored by `wait` and `threads`.
- `threads` paginates every review thread, so it never hides a finding past the first page.
