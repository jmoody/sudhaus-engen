# Terraform for engen-brews

This directory holds the Terraform configuration for engen-brews's Azure infrastructure. The remote-state backend that every root points at is provisioned by `script/tfstate-bootstrap` and is never managed by Terraform.

## Remote state

State lives in a dedicated, RBAC-only Azure storage account. The backend resources are named by purpose rather than by environment, because state is shared infrastructure and each subscription gets exactly one state account.

| Item            | Value                        |
| --------------- | ---------------------------- |
| Resource group  | `engen-brews-tfstate-rg`     |
| Storage account | `engenbrewstfstate<suffix>`  |
| Container       | `tfstate`                    |
| Blob key        | `<env>.tfstate`              |

The `<suffix>` is the first six characters of the SHA-256 hash of the lowercased subscription id, so the account name is deterministic and re-derivable at cutover without any bookkeeping. For the current subscription the account is `engenbrewstfstate167748`, which is the name committed in `backend.hcl`.

`script/tfstate-bootstrap` provisions the resource group, storage account, blob container, and the operator's `Storage Blob Data Contributor` role assignment. It is idempotent, so re-running it is a no-op, and it is subscription-portable, so pointing it at a fresh subscription reproduces the whole backend. Terraform must never manage these resources: keeping them out of every `*.tf` file guarantees a workload stack's `terraform destroy` can never delete the account holding its own state, and it keeps `make review` credential-free.

## Resource providers

Azure gates each resource type behind a subscription-scoped resource provider that must be registered before any resource of that type can be created. engen-brews depends on five providers; `Microsoft.App` (Container Apps) gates the workload compute, and the other four back the container registry, Log Analytics, metrics, and DNS/custom-domain networking.

| Provider                        | Backs                            |
| ------------------------------- | -------------------------------- |
| `Microsoft.App`                 | Container Apps                   |
| `Microsoft.ContainerRegistry`   | Azure Container Registry         |
| `Microsoft.OperationalInsights` | Log Analytics                    |
| `Microsoft.Insights`            | Azure Monitor metrics            |
| `Microsoft.Network`             | DNS zone and custom-domain certs |

`script/register-providers` registers all five. Registration is subscription-scoped state that Terraform does not own, so it lives in a bash script alongside `script/tfstate-bootstrap` rather than in any `*.tf` file, which keeps a workload stack's `terraform destroy` from touching it and keeps `make review` credential-free. The script is idempotent, so re-running it is a no-op, and it registers the full set rather than only the currently-missing providers so that pointing it at a fresh subscription at production cutover reproduces the whole set. Run `make az-login` first, then:

```bash
script/register-providers
```

## Region

Every engen-brews Azure workload resource is pinned to **West Europe** (`westeurope`). Pinning to a single EU region is a compliance decision: it keeps all data in one EU geography and avoids international-transfer complexity. The remote-state account (`script/tfstate-bootstrap`) is created in the same region.

The pin is **explicit, never defaulted**. The value lives once in `region.tfvars` as `location = "westeurope"`, a committed non-secret data file shared by every root, exactly as `backend.hcl` is shared. Each root declares `variable "location" {}` with **no default** and wires `var.location` into every resource's `location` argument. Every plan or apply passes the shared value explicitly:

```bash
terraform plan -var-file=../../region.tfvars
```

Because the variable has no default, a plan that forgets the `-var-file` fails loudly rather than silently falling back to a provider region.

## Layout

The tree seeds only the shared, root-agnostic artifacts. Workload stacks add their own subtrees.

| Path                   | Purpose                                             |
| ---------------------- | --------------------------------------------------- |
| `backend.hcl`          | Partial azurerm backend config, shared by all roots |
| `region.tfvars`        | Pinned region (`westeurope`), shared by all roots   |
| `.gitignore`           | Keeps state, plans, and caches out of git           |
| `modules/<component>/` | Reusable modules (added by workload stacks)         |
| `envs/<env>/`          | Per-environment roots (added by workload stacks)    |
| `envs/prod/`           | The prod workload root (see "The prod root" below)  |

Each root declares an empty `backend "azurerm" {}` block and inherits the account, resource group, and container from the shared partial config. Each root supplies its own state key, so one `backend.hcl` serves every stack.

## The prod root

`envs/prod/` is the first concrete workload root. Its state key is `prod.tfstate` and every resource it later owns is named `engen-brews-prod-<resource>`, following the `<project>-<env>-<resource>` convention.

The root pins the `hashicorp/azurerm` provider with `~> 5.0`. The subscription is an explicit input rather than a committed literal, because this repository is public and Terraform must stay subscription-portable. The `subscription_id` variable has no default and is wired into the provider, so a missing value fails loudly instead of silently targeting the Azure CLI's active subscription; supply it out-of-band, for example `export TF_VAR_subscription_id=<id>` before running `terraform`.

At this bootstrap stage the root declares only its backend, provider, region pin, and the `common_tags` local carrying the required `service = "engen-brews"` and `environment = "production"` tags. It provisions no resources yet. The Container Apps environment, container registry, Log Analytics workspace, DNS zone, and custom-domain resources described in ADR-0001 are added in later changes and will each merge `local.common_tags`.

## Running Terraform for the prod root

`script/terraform` wraps the prod root so operators do not repeat the backend config, state key, region var-file, and subscription wiring by hand. It maps the repo-wide `AZ_SUBSCRIPTION_ID` onto `TF_VAR_subscription_id` (never committed), reuses the repo-local Azure session under `.azure/`, and drives Terraform with `-chdir=terraform/envs/prod`. Sign in first, then init once and plan/apply as usual:

```bash
make az-login
make tf-init          # one-time per root (or after backend/provider changes)
make plan             # review; writes the plan to terraform/envs/prod/tf.plan
make apply            # applies the saved tf.plan, so it runs exactly what was reviewed
```

`make plan` always saves to `tf.plan` (gitignored via `*.plan`) and `make apply` applies that saved file, so the applied changes are exactly the reviewed plan rather than a fresh, possibly-drifted plan. Each target forwards `ARGS` to Terraform, and `script/terraform {init|plan|apply}` can be called directly when finer control is needed. `AZ_SUBSCRIPTION_ID` is required; the Azure scripts load it from the repo-local, gitignored `.env` when it is not already exported, so an explicit environment value always wins and the scripts fail loudly when it is set in neither place.

## Initialising a root by hand

The wrapper above is the normal path. Terraform runs operator-locally, not in CI. To drive a root directly (for the prod root, `key=prod.tfstate`):

```bash
terraform init -backend-config=../../backend.hcl -backend-config="key=<env>.tfstate"
```

The backend authenticates through Azure AD (`use_azuread_auth = true`); the account has shared key access disabled. State locking is automatic via blob lease and needs no configuration.

Plans and applies pass the shared region value explicitly, so the pinned region is inherited rather than re-declared per root. The subscription id is supplied out-of-band through `TF_VAR_subscription_id` so it never lands in a committed file:

```bash
export TF_VAR_subscription_id=<subscription-id>
terraform plan -var-file=../../region.tfvars
terraform apply -var-file=../../region.tfvars
```
