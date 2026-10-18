# How we work: Epic, Batch, Task

This document defines how planned work is broken down in this repository. Work is organized into three nested levels, listed here from smallest to largest.

## Levels

| Level | Scope / duration | Staffing               | GitHub form                         |
| ----- | ---------------- | ---------------------- | ----------------------------------- |
| Task  | 1-2 days         | 1 engineer + assistant | Issue; one ACE-FCA cycle; one PR    |
| Batch | 1-2 weeks        | 1 engineer + assistant | Issue grouping its task sub-issues  |
| Epic  | 1-3 months       | 1 engineer             | Issue grouping its batch sub-issues |

## Rules

- Not every task needs a batch, and not every batch needs an epic. A task with no batch, or a batch with no epic, is simply a top-level issue.
- Every epic needs batches, and every batch needs tasks.
- Only a task maps to code: one ACE-FCA cycle and one PR. Batches and epics are tracking issues that group their children and open no PR of their own.
- Organize the tree with GitHub **sub-issues**: tasks are sub-issues of their batch, batches are sub-issues of their epic.
- Track cross-item order with the GitHub issue-dependency API (Blocking / Depends on), not prose. Add a dependency with `POST /repos/{owner}/{repo}/issues/{n}/dependencies/blocked_by -F issue_id={blocker_db_id}` (the blocker's numeric database id, not its issue number).
- Give each batch a semantic title prefix that links it to its epic, for example `[Accounting N]` or `[Remote Service N]`. Use a prefix whenever an epic exists.
- See `.github/ace-fca/README.md` for the ACE-FCA phase workflow a task follows.
