# Terraform for sudhaus-engen

This directory holds the Terraform configuration for sudhaus-engen's Azure infrastructure. The remote-state backend that every root points at is provisioned by `script/tfstate-bootstrap` and is never managed by Terraform.

## Remote state

State lives in a dedicated, RBAC-only Azure storage account. The backend resources are named by purpose rather than by environment, because state is shared infrastructure and each subscription gets exactly one state account.

| Item            | Value                        |
| --------------- | ---------------------------- |
| Resource group  | `sudhaus-engen-tfstate-rg`   |
| Storage account | `sudhausengentf<suffix>`     |
| Container       | `tfstate`                    |
| Blob key        | `<env>.tfstate`              |

The `<suffix>` is the first six characters of the SHA-256 hash of the lowercased subscription id, so the account name is deterministic and re-derivable at cutover without any bookkeeping. For the current subscription the account is `sudhausengentf167748`, which is the name committed in `backend.hcl`. The account name is `sudhausengentf` plus the suffix, 20 characters, because Azure limits storage account names to 24 lowercase letters and digits.

`script/tfstate-bootstrap` provisions the resource group, storage account, blob container, and the operator's `Storage Blob Data Contributor` role assignment. It is idempotent, so re-running it is a no-op, and it is subscription-portable, so pointing it at a fresh subscription reproduces the whole backend. Terraform must never manage these resources: keeping them out of every `*.tf` file guarantees a workload stack's `terraform destroy` can never delete the account holding its own state, and it keeps `make review` credential-free.

## Resource providers

Azure gates each resource type behind a subscription-scoped resource provider that must be registered before any resource of that type can be created. sudhaus-engen depends on six providers; `Microsoft.App` (Container Apps) gates the workload compute, and the other five back the container registry, Log Analytics, metrics, managed identities, and DNS/custom-domain networking.

| Provider                        | Backs                            |
| ------------------------------- | -------------------------------- |
| `Microsoft.App`                 | Container Apps                   |
| `Microsoft.ContainerRegistry`   | Azure Container Registry         |
| `Microsoft.OperationalInsights` | Log Analytics                    |
| `Microsoft.Insights`            | Azure Monitor metrics            |
| `Microsoft.ManagedIdentity`     | User-assigned managed identities |
| `Microsoft.Network`             | DNS zone and custom-domain certs |

`script/register-providers` registers all six. Registration is subscription-scoped state that Terraform does not own, so it lives in a bash script alongside `script/tfstate-bootstrap` rather than in any `*.tf` file, which keeps a workload stack's `terraform destroy` from touching it and keeps `make review` credential-free. The script is idempotent, so re-running it is a no-op, and it registers the full set rather than only the currently-missing providers so that pointing it at a fresh subscription at production cutover reproduces the whole set. Run `make az-login` first, then:

```bash
script/register-providers
```

## Region

Every sudhaus-engen Azure workload resource is pinned to **Sweden Central** (`swedencentral`). Pinning to a single EU region is a compliance decision: it keeps all data in one EU geography and avoids international-transfer complexity. The remote-state account (`script/tfstate-bootstrap`) is created in the same region.

The pin is **explicit, never defaulted**. The value lives once in `region.tfvars` as `location = "swedencentral"`, a committed non-secret data file shared by every root, exactly as `backend.hcl` is shared. Each root declares `variable "location" {}` with **no default** and wires `var.location` into every resource's `location` argument. Every plan or apply passes the shared value explicitly:

```bash
terraform plan -var-file=../../region.tfvars
```

Because the variable has no default, a plan that forgets the `-var-file` fails loudly rather than silently falling back to a provider region.

## Layout

The tree seeds only the shared, root-agnostic artifacts. Workload stacks add their own subtrees.

| Path                   | Purpose                                             |
| ---------------------- | --------------------------------------------------- |
| `backend.hcl`          | Partial azurerm backend config, shared by all roots |
| `region.tfvars`        | Pinned region (`swedencentral`), shared by all roots |
| `.gitignore`           | Keeps state, plans, and caches out of git           |
| `modules/<component>/` | Reusable modules (added by workload stacks)         |
| `envs/<env>/`          | Per-environment roots (added by workload stacks)    |
| `envs/prod/`           | The prod workload root (see "The prod root" below)  |

Each root declares an empty `backend "azurerm" {}` block and inherits the account, resource group, and container from the shared partial config. Each root supplies its own state key, so one `backend.hcl` serves every stack.

## The prod root

`envs/prod/` is the first concrete workload root. Its state key is `prod.tfstate` and every resource it owns is named `sudhaus-engen-prod-<resource>`, following the `<project>-<env>-<resource>` convention. Two resources are exceptions. The Container Registry's name must be globally unique and alphanumeric-only, so it reuses the state account's scheme and is `sudhausengenprodacr<suffix>`. The public DNS zone is named `sudhaus-engen.de`, because a DNS zone's name is the domain it answers for.

The root pins the `hashicorp/azurerm` provider with `~> 5.0`. The subscription is an explicit input rather than a literal in any `*.tf` file, because Terraform must stay subscription-portable. The `subscription_id` variable has no default and is wired into the provider, so a missing value fails loudly instead of silently targeting the Azure CLI's active subscription; supply it out-of-band, either through `script/terraform` (which reads it from `.azure/config`) or with `export TF_VAR_subscription_id=<id>` before running `terraform`.

The root provisions the resource group, a Log Analytics workspace with 30-day retention, a Container Registry with admin credentials disabled, a user-assigned identity holding `AcrPull` on the registry, an `AcrPush` grant for the operator who runs the apply, a Container Apps environment, the Container App, the public DNS zone for `sudhaus-engen.de` with its apex and verification records, and the custom domain with its Azure-managed certificate. Every resource carries the required `service = "sudhaus-engen"` and `environment = "production"` tags through the `common_tags` local.

The Container App runs in single-revision mode with `min_replicas = 1` and external ingress on port 8000, the port the site listens on. Its image is a placeholder, `mcr.microsoft.com/dotnet/samples:aspnetapp` with `ASPNETCORE_HTTP_PORTS=8000`, chosen because the target port is fixed at 8000 and that image honours a port setting. A `lifecycle` block ignores image changes, so promoting a real build with `az containerapp update --image` survives the next apply. The environment sends console and system logs to the workspace; there is no diagnostic setting for `ContainerAppHTTPLogs`, so no HTTP access logs are collected. The root outputs the resource group name, the registry login server, the app name, the app's default host name, the DNS zone's name servers, and the environment name, custom domain, and certificate id that `script/bind-custom-domain` reads.

## DNS and the INWX delegation

`sudhaus-engen.de` is registered at INWX and hosted on Azure DNS, as ADR 0001 decided. Terraform owns only the hosting: `azurerm_dns_zone.prod` in the prod root. The registration itself, and the name-server entry that points the domain at Azure, stay with the registrar and are an operator step.

The zone takes no `location`, because a public DNS zone is a global resource. It holds two records, both owned by the custom-domain binding described below: an apex `A` record and the `asuid` `TXT` record.

**Order matters.** Create the zone in Azure *before* touching anything at INWX. When a `.de` delegation is changed, DENIC checks the new name servers, and the change fails (INWX sends an `UPDATE FAILED` mail) if the zone does not exist on them yet.

The first apply creates *only* the zone. The custom domain and the managed certificate both verify themselves through public DNS, which still answers from INWX until the delegation lands, so applying them before step 4 fails: Azure cannot resolve the `asuid` record it is looking for, however correct the record is inside Azure DNS.

1. Create the zone and read its name servers:

   ```bash
   make az-login
   make plan ARGS="-target=azurerm_dns_zone.prod"
   make apply
   script/terraform output dns_zone_name_servers
   ```

2. At INWX, open the domain and enter the Azure name servers under **Externe Nameserver**. At least two are required; enter all four that Azure assigned. Save the change.

3. Wait. A changed `.de` delegation takes 3 to 48 hours to become fully active.

4. Confirm the delegation from a public resolver:

   ```bash
   dig +short NS sudhaus-engen.de @8.8.8.8
   ```

   The answer is the Azure name servers (`ns1-NN.azure-dns.com.` and siblings) once the change has propagated. Until then it is the INWX name servers (`ns.inwx.de.` and siblings), which is the expected answer rather than a failure.

5. Apply the rest of the root, which now includes the records, the custom domain, and the certificate, and bind the certificate as described under "Custom domain and managed certificate" below:

   ```bash
   make plan
   make apply
   make bind-custom-domain
   ```

Steps 1 to 5 are the first-time delegation only. Once `sudhaus-engen.de` resolves from Azure, every later change is an ordinary `make plan` and `make apply`.

DNSSEC is deliberately not configured. INWX's one-click automatic mode must not be used with external name servers, and signing on the Azure side has no azurerm resource today, so it would need a new provider dependency or a manual step plus a DS record entered by hand at INWX.

## Custom domain and managed certificate

`https://sudhaus-engen.de` is served by the Container App itself under an Azure-managed certificate, so no certificate automation runs on the operator's side. Four resources in the prod root carry it, and one script finishes the job.

| Resource                                                     | Role                                                                       |
| ------------------------------------------------------------ | -------------------------------------------------------------------------- |
| `azurerm_dns_a_record.apex`                                  | Apex `A` record to the Container Apps environment's static ingress address |
| `azurerm_dns_txt_record.asuid`                               | `asuid` `TXT` record holding the app's custom-domain verification id       |
| `azurerm_container_app_custom_domain.prod`                   | Puts the host name `sudhaus-engen.de` on the app, unbound                  |
| `azurerm_container_app_environment_managed_certificate.prod` | Issues and renews the certificate, validated over HTTP                     |

The apex is an `A` record rather than a `CNAME` because a zone apex cannot hold a `CNAME`; it points at the environment's single static ingress address, which Azure keeps for the life of the environment. Both DNS records exist before the host name is added, since Azure resolves `asuid.sudhaus-engen.de` and compares it with the app's verification id before accepting the domain. The custom domain declares that ordering with `depends_on`, because neither record is one of its arguments.

The host name and the certificate are two resources rather than one binding, and Terraform cannot join them. Supplying `container_app_environment_certificate_id` on the custom domain needs a certificate that already exists, and the certificate cannot be created first: ARM rejects it with `RequireCustomHostnameInEnvironment` until the host name is on an app in the environment. A custom domain that referenced the certificate would sit in a dependency cycle with it.

So the apply adds the host name alone. Azure records it as `bindingType: Disabled` and does not attach the issued certificate by itself, so until the binding is made the site answers HTTP but resets the connection on HTTPS. `script/bind-custom-domain` performs that one join:

```bash
make bind-custom-domain
```

Run it once after the apply that creates the custom domain. It is idempotent, so re-running it is a no-op, and certificate renewal does not need it again. Because the binding is made outside Terraform, the custom domain ignores changes to `certificate_binding_type` and `container_app_environment_certificate_id`; without that, every later plan would read Azure's binding as drift and replace the resource.

HTTP is the validation method for an apex domain, and both issuance and every automatic renewal reach the app over the custom domain. That is why the app runs with `min_replicas = 1`: a scaled-to-zero app cannot answer the validation request. The ingress sets `allow_insecure_connections = false`, so `http://sudhaus-engen.de` redirects to HTTPS.

The zone publishes no `CAA` record, which leaves every public CA free to issue, including the DigiCert account behind the Azure-managed certificate. There is no `www` name and no redirect in the application.

Issuance takes a few minutes, and `make apply` blocks until Azure finishes. On a zone that already resolves from Azure, the full sequence and its checks are:

```bash
make plan
make apply
make bind-custom-domain
curl -sS -o /dev/null -w '%{http_code}\n' https://sudhaus-engen.de
curl -sS -o /dev/null -w '%{http_code} %{redirect_url}\n' http://sudhaus-engen.de
make plan
```

The first `curl` returns `200`, the second `301 https://sudhaus-engen.de/`, and the closing plan reports no changes.

## Running Terraform for the prod root

`script/terraform` wraps the prod root so operators do not repeat the backend config, state key, region var-file, and subscription wiring by hand. It maps the repo-wide `AZ_SUBSCRIPTION_ID` onto `TF_VAR_subscription_id`, reuses the repo-local Azure session under `.azure/`, and drives Terraform with `-chdir=terraform/envs/prod`. Sign in first, then init once and plan/apply as usual:

```bash
make az-login
make tf-init          # one-time per root (or after backend/provider changes)
make plan             # review; writes the plan to terraform/envs/prod/tf.plan
make apply            # applies the saved tf.plan, so it runs exactly what was reviewed
```

`make plan` always saves to `tf.plan` (gitignored via `*.plan`) and `make apply` applies that saved file, so the applied changes are exactly the reviewed plan rather than a fresh, possibly-drifted plan. Each target forwards `ARGS` to Terraform, and `script/terraform {init|plan|apply|output}` can be called directly when finer control is needed; `output` re-reads a value from the current state, for example `script/terraform output dns_zone_name_servers`. `AZ_SUBSCRIPTION_ID` resolves in order from the environment, the repo-local gitignored `.env`, and `defaults.subscription` in the tracked `.azure/config`, so an explicit environment value always wins and the scripts fail loudly when none of the three sets it. To target another subscription, set `AZ_SUBSCRIPTION_ID` or change `defaults.subscription` in `.azure/config`.

## Initialising a root by hand

The wrapper above is the normal path. Terraform runs operator-locally, not in CI. To drive a root directly (for the prod root, `key=prod.tfstate`):

```bash
terraform init -backend-config=../../backend.hcl -backend-config="key=<env>.tfstate"
```

The backend authenticates through Azure AD (`use_azuread_auth = true`); the account has shared key access disabled. State locking is automatic via blob lease and needs no configuration.

Plans and applies pass the shared region value explicitly, so the pinned region is inherited rather than re-declared per root. The subscription id is supplied out-of-band through `TF_VAR_subscription_id` so no `*.tf` or `*.tfvars` file holds it:

```bash
export TF_VAR_subscription_id=<subscription-id>
terraform plan -var-file=../../region.tfvars
terraform apply -var-file=../../region.tfvars
```
