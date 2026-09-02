---
name: fix-markdown
description: "Format or clean up Markdown files to match .github/instructions/markdown.instructions.md. Use when asked to fix, reformat, reflow, or tidy Markdown, unwrap hard-wrapped prose, or align Markdown tables."
license: MIT
---

# Fix Markdown formatting

Bring Markdown files into compliance with `.github/instructions/markdown.instructions.md`, the single source of truth for Markdown style in this repo. That file defines exactly two mechanical rules this skill enforces:

1. **Line wrapping** - do not hard-wrap prose. Each narrative paragraph or list item is one logical line; only semantically meaningful breaks (poetry, addresses, intentional `<br>`) stay split.
2. **Table formatting** - every table column is vertically aligned in the source. Cells are padded with trailing spaces so pipes line up, and the separator row keeps its `:` alignment markers (`:---` left, `---:` right, `:---:` center).

Read `.github/instructions/markdown.instructions.md` first; if it changes, it wins over this skill.

## When to use

Use this skill whenever the user asks to fix, format, reflow, tidy, or lint Markdown, or to unwrap wrapped prose or align tables, in one or many `.md` files.

## How to run it

The bundled script does both transforms and is idempotent, so re-running on a compliant file changes nothing. It runs under any POSIX `awk` (including the BSD `awk` shipped with macOS) in the `C` locale and counts UTF-8 characters rather than bytes, so multibyte glyphs such as `x`, arrows, and en dashes stay aligned.

Check what is non-compliant without touching files:

```bash
.github/skills/fix-markdown/scripts/fix-markdown.sh --check path/to/*.md
```

Fix files in place (use `-v` to list what changed):

```bash
.github/skills/fix-markdown/scripts/fix-markdown.sh -v path/to/*.md
```

After fixing, re-run with `--check`; a clean exit confirms compliance.

## What the script does

| Step         | Tool                       | Effect                                                            |
| ------------ | -------------------------- | ----------------------------------------------------------------- |
| Unwrap prose | `scripts/unwrap-prose.awk` | Joins wrapped paragraph and list-item lines into one logical line |
| Align tables | `scripts/align-tables.awk` | Repads every table cell so pipes align; preserves `:` markers     |
| Verify       | `--check` re-run           | Idempotent, so no diff means the file is compliant                |

Fenced code blocks, headings, blockquotes, and table rows are never reflowed as prose, and only pipe blocks whose second line is a separator row are treated as tables.

## Notes and limits

- Requires only a POSIX `awk`; no `gawk` install is needed.
- The script writes through a sibling `FILE.tmp` and never uses a system temp dir.
- It does not touch anything beyond wrapping and table alignment. It does not change heading case, replace em dashes, or reword content; do those edits by hand when the task calls for them.
- This skill has no opinion on whether a file is tracked by git; it happily formats gitignored files too (for example files under `tmp/` or `scratch/`).
