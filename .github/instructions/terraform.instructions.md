---
applyTo: "**/*.tf,terraform/**"
---

# Terraform

Sudhaus Engen's Terraform provisions the project's Azure infrastructure. It lives under `terraform/`, targets the `hashicorp/azurerm` provider, and keeps its remote state in a dedicated Azure Storage backend. Read `terraform/README.md` for the full backend, region, and root-layout story; this file is the authoring and review contract that companion `.github/instructions/*.instructions.md` files do not already cover.

Terraform runs operator-locally, never in CI. CI does not run `terraform`, and `make review` stays credential-free.

## Required tags

Every Azure resource that supports tags **MUST** carry both of these keys:

```hcl
tags = {
  service     = "sudhaus-engen"
  environment = "production"
}
```

- `service` is always `"sudhaus-engen"`.
- `environment` is one of `production`, `staging`, or `lab`, matching the root the resource belongs to.

When a root defines more than a couple of resources, declare the pair once in `locals` and `merge` in any resource-specific tags:

```hcl
locals {
  common_tags = {
    service     = "sudhaus-engen"
    environment = "production"
  }
}

resource "azurerm_resource_group" "prod" {
  name     = "sudhaus-engen-prod-rg"
  location = var.location

  tags = merge(local.common_tags, {
    component = "workload"
  })
}
```

Existing resources under `terraform/envs/prod/` predate this requirement and must be backfilled with these tags.

## Azure resource exploration workflow

Before implementing a new Azure resource, use the Azure CLI to explore its options. Sign in first with `make az-login`.

```bash
# List available resource types for a provider
az provider show --namespace Microsoft.App --query "resourceTypes[].resourceType"

# Check resource availability in the pinned region
az provider show --namespace Microsoft.App --query "resourceTypes[?resourceType=='managedEnvironments'].locations"

# Inspect creation syntax
az containerapp env create --help
```

Then implement in Terraform:

- Reference any non-obvious Azure CLI findings in comments, and document resource dependencies the graph does not make obvious.
- Run `make plan` and review the output. `make plan` writes a saved plan to `terraform/envs/prod/tf.plan`; `make apply` applies that saved file, so the applied change is exactly what was reviewed.

## Naming

Resources follow the `<project>-<env>-<resource>` convention, for example `sudhaus-engen-prod-rg` and `sudhaus-engen-prod-cae`. The project segment is always `sudhaus-engen`.

Where a resource name must be globally unique and alphanumeric-only (Storage accounts, Container Registries), reuse the state account's scheme: a fixed prefix followed by the first six hex characters of `sha256(lower(var.subscription_id))`. The suffix is deterministic and re-derivable, so the name needs no bookkeeping and stays subscription-portable.

```hcl
resource "azurerm_container_registry" "prod" {
  name = "sudhausengenprodacr${substr(sha256(lower(var.subscription_id)), 0, 6)}"
  # ...
}
```

## Project context

This is a service-layer Terraform project for a **public** repository. Two rules shape every root:

1. **Subscription-portable.** The subscription id is an explicit input (`variable "subscription_id"`, no default), supplied through `TF_VAR_subscription_id` and never written as a literal in a `*.tf` or `*.tfvars` file. `script/terraform` reads it from `AZ_SUBSCRIPTION_ID`, `.env`, or `defaults.subscription` in the tracked `.azure/config`. The id is an identifier, not a credential, so it may be public. A missing value must fail loudly rather than silently target the Azure CLI's active subscription.
2. **Region-pinned.** Every workload resource is pinned to West Europe (`westeurope`). The value lives once in the shared, committed `region.tfvars`; each root declares `variable "location"` with **no default** and passes `-var-file=../../region.tfvars` on every plan and apply, so a forgotten region fails loudly.

Remote state lives in a dedicated azurerm Storage backend (`sudhaus-engen-tfstate-rg` / `sudhausengentf<suffix>` / container `tfstate`, blob key `<env>.tfstate`), provisioned by `script/tfstate-bootstrap` and **never** managed by Terraform. Subscription-scoped resource-provider registration is likewise handled out-of-band by `script/register-providers`. Keeping both out of every `*.tf` file guarantees a `terraform destroy` cannot delete the state account or deregister providers, and keeps `make review` credential-free.

## File structure

Shared, root-agnostic artifacts live at the top of `terraform/`; each environment is a separate root under `envs/<env>/`.

| Path            | Purpose                                                                                   |
| --------------- | ----------------------------------------------------------------------------------------- |
| `backend.hcl`   | Partial azurerm backend config (account, resource group, container), shared by all roots  |
| `region.tfvars` | Pinned region (`westeurope`), shared by all roots                                      |
| `.gitignore`    | Keeps state, plans, and provider caches out of git                                        |
| `envs/<env>/`   | Per-environment root; supplies its own `key=<env>.tfstate` at init time                   |

Within a root, use the following standard layout:

| File           | Purpose                                                                                   |
| -------------- | ----------------------------------------------------------------------------------------- |
| `terraform.tf` | `terraform {}` block: backend, `required_providers`, `required_version`, provider config  |
| `main.tf`      | Resource definitions and data sources                                                     |
| `variables.tf` | Input variable declarations                                                               |
| `outputs.tf`   | Output value declarations                                                                 |

Do not put the `terraform {}` block, provider version constraints, or the backend block in `main.tf`; these belong in `terraform.tf`.

## Version pinning

Each root pins `required_version = ">= 1.9.0"` and the `hashicorp/azurerm` provider at `~> 5.0` in `terraform.tf`. Commit `.terraform.lock.hcl` with checksums for every operator platform in use so provider downloads are reproducible.

If a root ever consumes a registry module, its `module` block **MUST** include a `version` attribute.

## Code organization

Group related resources with section comment blocks:

```hcl
# ------------------------------------------------------------------------------
# LOCALS
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# DATA SOURCES
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# RESOURCES
# ------------------------------------------------------------------------------
```

## Variable descriptions

Every `variable` block **MUST** include a `description`.

```hcl
variable "location" {
  description = "Azure region for every resource in this root, supplied via -var-file=../../region.tfvars."
  type        = string
}
```

When a `variable` has a `validation` block, bound it to the narrowest range the use case actually needs rather than accepting broader inputs. When merging user-supplied values with hard-coded ones, wrap the result in `distinct()` so set-typed attributes do not produce perpetual plan diffs.

## Running Terraform

`script/terraform` (driven by the `Makefile`) is the normal path: it wires the partial backend config, the state key, the region var-file, and the subscription id, and drives Terraform with `-chdir=terraform/envs/prod`.

```bash
make az-login   # sign in (reuses the repo-local Azure session under .azure/)
make tf-init    # one-time per root, or after backend/provider changes
make plan       # review; writes terraform/envs/prod/tf.plan
make apply      # applies the saved tf.plan
```

Each target forwards `ARGS` to Terraform, and `script/terraform {init|plan|apply}` can be called directly when finer control is needed. Override the subscription by setting `AZ_SUBSCRIPTION_ID` in the environment.

## Validation

There is currently no Terraform test suite. Two layers of validation apply.

`make lint` (and therefore `make review`) runs `script/terraform-lint`, a credential-free check that formats with `terraform fmt -check` and validates each root with `terraform validate` against a throwaway `-backend=false` copy. It never contacts Azure, never runs plan or apply, and leaves an operator's backend-initialised `.terraform` untouched. When `terraform` is not installed the step prints a note and passes, since `terraform` is an operator-only tool rather than a bootstrap-required dependency.

For real infrastructure changes, also validate against the live backend: sign in and run a plan (`make az-login`, then `make tf-init` if needed, then `make plan`) and review the saved plan before `make apply`. `make review` never runs plan or apply and stays credential-free.
