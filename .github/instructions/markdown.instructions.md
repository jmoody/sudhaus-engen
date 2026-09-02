---
applyTo: "**/*.md"
---

# Markdown style instructions

This file is the single source of truth for Markdown authoring standards in this project. Other files should reference it rather than duplicate these rules.

## Line wrapping

- Do **not** hard-wrap Markdown prose to 80 characters (or any other fixed column).
- Let lines flow naturally; rely on the renderer and the editor's soft-wrap.
- Hard line breaks inside a paragraph are reserved for cases where they have semantic meaning (e.g., poetry, addresses, intentional `<br>` substitutes). Plain narrative paragraphs stay on a single logical line.
- This applies to all `.md` files: documentation, READMEs, issue/PR templates, ACE-FCA research/plan/retro documents, and agent definitions.

## Table formatting

- All columns must be **vertically aligned** in the source. Pad cells with trailing spaces so pipes line up across every row.
- The header separator row uses dashes sized to the column width, with `:` markers preserved for alignment direction (`:---` left, `---:` right, `:---:` center).
- Example:

  ```markdown
  | Skill                | Time | Why                       |
  | -------------------- | ---: | ------------------------- |
  | Broker Relations V   | 1.5d | Fee floor on every order  |
  | Retail V             |   8d | Wholesale prerequisite    |
  ```

- This applies to every Markdown table in the repo.
