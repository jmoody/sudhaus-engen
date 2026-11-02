---
name: bootstrap-worktree
description: "Create a build-ready git worktree for this repo in one command: new branch, carried-over .env, Azure session, and uncommitted ACE-FCA documents, then bootstrap and verify with make review. Use when asked for a worktree to work an issue, a stacked-PR worktree off a parent branch, or parallel worktrees for several agents."
license: MIT
---

# Bootstrap a development worktree

`script/bootstrap-worktree` takes an existing checkout to a worktree that already passes `make review`. It creates the branch, copies the state a checkout does not carry (`.env`, the gitignored `.azure/` login session, and uncommitted ACE-FCA research, plan, and retro documents), then runs `script/bootstrap` and `make review`.

Run `script/bootstrap-worktree --help` for the arguments.

## Steps

1. Pick the branch name: `<type>/issue-<N>-<slug>`, where type is `feat`, `fix`, or `chore` (`feat/issue-3-impressum`). Drop `issue-<N>` when no issue exists.
2. Run `script/bootstrap-worktree <branch-name>` from inside the checkout. For a stacked pull request, pass the parent feature branch as a second argument so the new branch forks from it instead of `HEAD`.
3. Copy the worktree path to the clipboard with `pbcopy` and report it. The script prints it on the last line; it is `../sudhaus-engen-worktrees/<branch-name>`.

The run ends green or not at all. `make review` is the last step, and any failure after the worktree exists removes that worktree and deletes its branch, so a failed run leaves no debris to clean up.

## Parallel agents

One worktree per agent, one branch per worktree. Bootstrap each worktree before dispatching its agent, and pass the agent its worktree path as the working directory. Agents sharing a worktree share a branch and a `bin/`, and overwrite each other's builds.

Uncommitted ACE-FCA documents are copied at bootstrap, not synced. An agent implementing a plan that is still uncommitted works from the copy that existed when its worktree was created; later edits in the source checkout do not reach it. Commit the plan first when several agents must all see the same version.

## Cleanup

Once the pull request merges, run `git worktree remove <path>` and `git branch -D <branch>` from the source checkout.

Keep the branch name of a live worktree fixed: renaming it deletes the worktree directory out from under every shell working in it. The name is cosmetic, and the pull request title carries the meaning.
