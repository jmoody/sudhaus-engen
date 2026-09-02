---
name: terraform-review
description: "Statically review the repo's Terraform against .github/instructions/terraform.instructions.md. Use when asked to review, lint, check, or audit Terraform under terraform/, or before opening a PR that touches *.tf files. Credential-free: never runs plan/apply or touches Azure."
license: MIT
---

# Review Terraform against the repo contract

Check the Terraform under `terraform/` against the authoring rules in `.github/instructions/terraform.instructions.md` before it reaches review, without any Azure credentials. Read that instructions file first; if it changes, it wins over this skill.

`terraform plan` is the only thing that proves a change against real Azure, but it needs `make az-login` and live credentials. This skill covers the mechanical, credential-free half: the tag/naming/structure contract that is invisible by inspection but obvious to a script, so a plan is never spent discovering a missing `description` or an untagged resource.

## When to use

Use this skill whenever the user asks to review, lint, check, or audit Terraform, or before opening a pull request that changes any `*.tf` file or anything under `terraform/`. It complements `make plan`; it does not replace it.

## What it checks

The checker enforces the parts of `.github/instructions/terraform.instructions.md` that can be verified statically:

- `terraform fmt -check` (skipped with a `NOTE` when the `terraform` binary is absent).
- No `versions.tf`; the `terraform {}` block lives in `terraform.tf`.
- No subscription id committed as a literal; it must be `var.subscription_id`.
- The `terraform {}` block and provider blocks live in `terraform.tf` (checked positively, so a misplaced block in any other file is caught).
- Every `variable` block has a `description`.
- `variable "location"` and `variable "subscription_id"` declare no `default`.
- Every taggable resource carries the required tags: heuristically, any `azurerm_*` resource that sets a `location` must declare `tags`, and every `tags` block must include `service = "engen-brews"` and an `environment` whose value is one of `production`, `staging`, or `lab`, matching the root (derived from its path). A `tags` value that references `common_tags` is accepted when a `locals` block defines `common_tags` with `service = "engen-brews"` and a valid `environment`.

The tag, block-placement, and variable checks are line-oriented heuristics tuned to this repo's simple, one-resource-per-block style, not a full HCL parser. Treat findings as a fast first pass, not a substitute for `make plan` and human review.

## How to run it

From the repository root, review every root under `terraform/`:

```bash
.github/skills/terraform-review/scripts/check-terraform.sh
```

Review specific roots, or quiet the per-root `OK` lines:

```bash
.github/skills/terraform-review/scripts/check-terraform.sh terraform/envs/prod
.github/skills/terraform-review/scripts/check-terraform.sh --quiet
```

The script prints one `FAIL` line per finding to stderr and exits non-zero if any root has a finding, so it slots into a pre-PR check. Fix every finding, then re-run until the output is clean, then proceed to `make plan` for the credentialed half of the review.
