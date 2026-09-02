---
title: Host on Azure Container Apps in West Europe, provisioned with Terraform and deployed as a Docker container
description: Decide the hosting and deploy topology for the brewing-calendar website.
---

# 1. Host on Azure Container Apps in West Europe, provisioned with Terraform and deployed as a Docker container

Date: 2026-09-02
Owner: @jmoody

## Status

Accepted

Revised 2026-09-02: this ADR originally selected an Azure Virtual Machine. It was reconsidered the same day, before any infrastructure was provisioned, in favour of Azure Container Apps. The VM approach is retained below as alternative A with the reason it lost, so the reversal is not lost. No Terraform, container, or DNS work had been built against the VM decision, so this is a rewrite in place rather than a superseding record.

## Context

The project is a single-developer brewing-calendar website for a German audience. It renders brew-day events plus the legally required German pages (Impressum, Datenschutzerklarung) and sets no cookies. The application ships as a Docker container, and its infrastructure is provisioned and maintained with Terraform.

The decision under record is the hosting and deploy topology: where the service runs, how it is provisioned, and how the application is delivered onto it. This is a deploy-topology choice that is costly to reverse once the container, Terraform modules, and monitoring are built around it, which is why it is recorded as an ADR.

The immediate driver is a concrete need: the site must serve HTTPS on a registered custom domain. On a self-managed host that means running and renewing certificates by hand (Let's Encrypt behind a reverse proxy); on a managed container platform it is a built-in, auto-renewing managed certificate bound to the domain. For a single developer running one low-traffic site, minimising that standing operational burden matters more than owning the host.

Because the audience is German, the choice must support a defensible EU data-residency posture: visitor data (including IP addresses that appear in access logs), event content, and backups should stay in the EU, and the provider relationship must be disclosable in the Datenschutzerklarung. A key nuance shapes every option: choosing an EU region fixes the physical location of data, but not legal sovereignty. Microsoft is a US company, so data resident in the EU can still fall under US lawful-access requests to its parent (the post-Schrems II concern). No EU-hosted-on-a-US-hyperscaler option removes this; it is handled by disclosure (naming Microsoft/Azure and the region as a processor, backed by the DPA and Standard Contractual Clauses), not by architecture.

### Constraints

- The application must run as a Docker container.
- Infrastructure must be provisioned and maintained with Terraform, with portable state so a development environment can be stood up on any machine.
- Only the developer may have access to the Terraform state and the Azure subscription.
- Exactly one production environment is required.
- The audience is German: EU data residency for logs, content, and backups must be defensible and disclosable.
- HTTPS on a custom domain is required, with the least standing operational burden practical.
- Deploying and monitoring should use Azure tooling.
- Exercising the developer's Azure and Terraform skills is an explicit goal of the project.

## Decision

We will host the service on Azure Container Apps (Consumption) in the West Europe region, provisioned and maintained with Terraform, and deployed as a Docker container.

1. Provision a Container Apps environment, an Azure Container Registry for the image, a Log Analytics workspace for logs, and supporting resources with Terraform, pinned to West Europe.
2. Build the application as a Docker image, push it to the registry, and run it as a Container Apps app served over the platform's HTTPS ingress.
3. Bind the registered custom domain to the app and secure it with an Azure-managed TLS certificate; manage DNS records with `azurerm_dns_zone`. Registering the domain itself is out of scope for Terraform and Azure (see Consequences).
4. Enforce residency by configuration: pin the Container Apps environment, the registry, and the Log Analytics workspace to West Europe, and avoid geo-redundant storage that would replicate data to a paired region outside the chosen geography.
5. Keep Terraform state portable and access-restricted (a dedicated azurerm backend per `.github/instructions/terraform.instructions.md`) so the environment can be recreated on any machine by the sole developer.
6. Use Azure tooling (Log Analytics, and Application Insights if added later) for monitoring the single production environment.
7. Disclose Microsoft/Azure (West Europe) as a processor in the Datenschutzerklarung, backed by the Microsoft DPA and Standard Contractual Clauses.

### Edge cases

- **Scale to zero.** Consumption can scale the app to zero replicas when idle, so the first request after an idle period pays a cold-start latency of a few seconds. For a low-traffic calendar this is acceptable; pinning `min_replicas = 1` removes it at the cost of always-on billing.
- **Domain registration.** Purchasing the domain is not a Terraform resource, and a `.de` domain requires a DENIC-accredited registrar that Azure App Service Domains does not offer. The domain is registered out-of-band; only DNS hosting and the custom-domain binding live in Terraform.

## Consequences

- There is no OS or host to patch or harden; Microsoft owns the host layer. This removes the standing maintenance a VM would impose on the sole developer.
- TLS certificates for the custom domain issue and renew automatically as Azure-managed certificates, so there is no Let's Encrypt automation to run or monitor. This directly satisfies the HTTPS-on-a-custom-domain requirement that motivated the decision.
- Consumption scale-to-zero makes idle compute cost near zero, which suits a low-traffic site; the tradeoff is cold-start latency on the first request after idle, or an always-on cost if `min_replicas` is raised.
- Compute and application logs sit in West Europe (the Container Apps environment plus a region-pinned Log Analytics workspace), giving a defensible EU/German residency posture. The residual US-jurisdiction risk is unchanged by platform choice and is mitigated by disclosing Microsoft/Azure as a processor under the DPA and SCCs, a documentation obligation that must be kept current.
- Container Apps introduces platform-specific behaviour (revisions, ingress, scale rules) that is itself a lock-in surface; migrating off Container Apps later is more work than moving a plain container off a VM.
- The build-and-deploy path is push-image-then-roll-a-revision rather than host provisioning, which is less to run than a VM plus reverse proxy but couples deployment to the registry and the platform's revision model.
- The explicit skill-building goal is met through a modern managed-Azure stack (Container Apps, Container Registry, managed identity, RBAC, Log Analytics, custom domains and managed certificates) rather than host administration; hands-on OS-level control is given up in exchange.
- Follow-up work this implies: provision the Terraform roots (resource group, Container Apps environment, registry, Log Analytics); wire the deploy pipeline (build, push, revision); create the DNS zone, custom-domain binding, and managed certificate; register the domain with an external registrar; author the Datenschutzerklarung processor disclosure; decide the calendar event format (separate ADR).

## Alternatives

### A. Azure Virtual Machine (originally selected)

**How it works**: Provision a Terraform-managed Azure VM in West Europe, run the same Docker image on it, and terminate TLS with a reverse proxy (Caddy, Traefik, or nginx) issuing Let's Encrypt certificates against the custom domain.

**Pros**:

1. Gives maximum host-level control over the OS, networking, and request logging, which is directly valuable when learning the full stack is a goal in itself.
2. Runs a plain container on a plain host with no managed-platform behaviours (revisions, ingress, scale rules) to learn or be constrained by, making it maximally portable off Azure later.
3. Pins compute, disks, access logs, event content, and backups to West Europe just as cleanly as Container Apps, giving an equivalent EU residency posture.

**Rejected because** for a low-traffic single-developer site the ongoing cost of owning OS patching, host hardening, and self-managed TLS renewal outweighs the control benefit, and Container Apps still exercises a rich Azure and Terraform skill set while giving managed TLS for free.

### B. Azure Static Web Apps

**How it works**: Host the site as static content on Azure Static Web Apps, provisioned with `azurerm_static_web_app`, with events authored as Markdown/YAML and published on Git push through a build step.

**Pros**:

1. Provides a clean Git-push-to-publish workflow that fits authoring events as human-readable files.
2. Requires no server or OS to maintain, minimizing operational burden.
3. Includes free managed TLS and custom-domain support on the free tier.

**Cons**:

1. Cannot host a Docker container, directly violating a hard constraint of the project.
2. Provides no comparable infrastructure to provision, so it serves the Azure/Terraform learning goal less than a container platform does.
3. Serves static assets from a globally distributed CDN with no EU data-residency guarantee for the static tier, weakening the German compliance story.

**Rejected because** it cannot run a Docker container and gives no EU residency guarantee for served content, breaking two hard constraints.

### C. GitHub Pages

**How it works**: Publish the site as static files from a Git repository using GitHub Pages, editing event files in the repo and letting the platform build and serve them.

**Pros**:

1. Offers the simplest possible publish workflow directly from the repository.
2. Costs nothing to host and requires no infrastructure to maintain.

**Cons**:

1. Was already ruled out by the developer as an option for this project.
2. Cannot run a Docker container and provides no Azure infrastructure to provision with Terraform.
3. Serves from global infrastructure with no EU data-residency guarantee and no control over request logging or headers.

**Rejected because** the developer has already excluded it, and it fails the Docker, Terraform, and EU-residency constraints regardless.

### D. European non-hyperscaler provider (Hetzner, IONOS, OVH, Scaleway)

**How it works**: Rent a VM or container host from an EU-headquartered provider and run the same Docker image there, provisioning with Terraform via the provider's Terraform integration where available.

**Pros**:

1. Gives the strongest jurisdictional story, since an EU-headquartered provider is not subject to US parent-company lawful-access in the way a US hyperscaler is.
2. Still runs the same Docker container, preserving the application packaging.
3. Often lower cost than equivalent hyperscaler compute.

**Cons**:

1. Abandons the explicit goal of exercising Azure skills, since the project would use a non-Azure provider.
2. Loses first-class Azure deployment and monitoring tooling, which the project intends to use.
3. Provider Terraform support and ecosystem maturity vary and may add integration friction.

**Rejected because** it discards the Azure/Terraform skill-building goal and the intended Azure deployment and monitoring tooling, which outweighs its jurisdictional edge for this low-stakes site.

## References

- [azurerm_container_app - Terraform Registry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app)
- [Custom domain names and managed certificates in Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/custom-domains-managed-certificates)
- [Azure Container Apps billing (Consumption plan and scale to zero)](https://learn.microsoft.com/en-us/azure/container-apps/billing)
- [Azure geographies and data residency](https://azure.microsoft.com/en-us/explore/global-infrastructure/data-residency/)
- [Microsoft EU Data Boundary](https://learn.microsoft.com/en-us/privacy/eudb/eu-data-boundary-learn)
