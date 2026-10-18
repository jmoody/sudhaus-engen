---
date: 2026-10-18T12:04:31+02:00
researcher: "GitHub Copilot"
git_commit: efec5bea8e29cf48e00f516687f6d21e0ec1f2fd
branch: main
repository: sudhaus-engen
topic: "Rolling out the German-language site: legal requirements in Germany, deployment, CSS, content, layout"
tags: [research, rollout, germany, impressum, datenschutz, deployment, tls, domain, css, layout, content]
status: complete
last_updated: 2026-10-18
last_updated_by: "GitHub Copilot"
last_updated_note: "Resolved the DENIC algorithm 13 question and researched the .ics feed, German dates, the web baseline, and Datenschutzerklärung operator duties; added decision points 16 to 19 and section 5.8"
---

# Research: Rolling out the German-language site

## Original Prompt

> @.github/prompts/research.prompt.md we need to make a plan for rolling out this site.  this is german site.  what are the requirements in germany?  we need a deployment strategy: we will start with scripts (I think we have a markdown file that records our decision).  we need a style (CSS). we need content. we need a layout.   I want to make issues to track these.  we have a how-we-work document that describes epics, batches, tasks.

---

**Date**: 2026-10-18T12:04:31+02:00 **Researcher**: GitHub Copilot **Git Commit**: efec5bea8e29cf48e00f516687f6d21e0ec1f2fd (the working tree has uncommitted and untracked changes, so line references are to local files and no GitHub permalinks are given) **Branch**: main **Repository**: sudhaus-engen

## Research Question

What exists today for rolling out the Sudhaus Engen site, and what do German rules require of it? The user named five areas: German requirements, a deployment strategy (starting with scripts), a style (CSS), content, and a layout. The user also wants to track these as GitHub issues using the epic, batch, and task levels from `docs/how-we-work.md`.

## Summary

The application is a single-route Go server that renders one embedded HTML template with the text "Hello world". It has no stylesheet, no shared layout, no event content, no Impressum page, and no Datenschutzerklärung page. The only route is `GET /{$}` (`internal/web/web.go:47-51`).

The deployment decision exists in two documents. ADR 0001 selects Azure Container Apps in West Europe with Terraform and Docker. `docs/deployment-with-scripts.md` records the 2026-10-18 decision to build, push, and promote images with scripts run from the operator's machine, with no CI/CD pipeline. That document is marked "idea, not yet planned or implemented". Neither of the two delivery scripts exists, the Terraform prod root declares no resources, and the domain `sudhaus-engen.de` was purchased by the user on 2026-10-18 after the first draft of this document. DNS still answers NXDOMAIN for it, so no name servers are set yet.

The operator answers (2026-10-18) fix the legal picture. The site is non-commercial and run by Joshua Moody as a private person in Baden-Württemberg, with the domain registered at INWX. The site will show no images yet, will use self-hosted public-domain fonts, and must log no user information.

German website law attaches a small set of duties to this kind of site. For a non-commercial private operator the Impressum duty most likely comes from § 18 Abs. 1 MStV, which asks for name and postal address only. The Datenschutzerklärung duty comes from Art. 12 and 13 DSGVO. A site that sets no cookies and loads no third-party resources avoids the consent duties under § 25 TDDDG. The accessibility law (BFSG) exempts micro-enterprises that offer services. The online dispute resolution platform was shut down with effect from 2025-07-20 (section 5.6), and the § 36 VSBG notice does not bind a one-person operator that has not committed to arbitration.

Two infrastructure findings affect the plan. The Container Apps environment can store logs in a Log Analytics workspace without the ingress request table, which holds client IP addresses, so the workspace can match the operator's rule that no personal data is logged (section 3). Microsoft documents that the app must be running for managed-certificate issuance and renewal, and the operator reads this as requiring at least one replica (section 4). Microsoft also processes some request-related data as an independent controller for its own business operations, which the privacy notice has to mention (section 5.2).

No GitHub issues exist in the repository. `docs/how-we-work.md` defines the Task, Batch, and Epic levels that the issues would use.

## Compact-mode eligibility

Not applicable. The research does not target a GitHub issue.

## Detailed Findings

### 1. Work tracking and process

- `docs/how-we-work.md` defines three levels: Task (1-2 days, one ACE-FCA cycle, one PR), Batch (1-2 weeks, groups task sub-issues), Epic (1-3 months, groups batch sub-issues).
- Only a task maps to code. Batches and epics are tracking issues that open no PR (`docs/how-we-work.md`, "Rules").
- Hierarchy uses GitHub sub-issues. Cross-item order uses the issue-dependency API (Blocking / Depends on), using the blocker's numeric database id.
- A batch title carries a semantic prefix naming its epic, for example `[Accounting N]`.
- `gh issue list --state all` returns no issues for `jmoody/sudhaus-engen` as of this research.
- `.github/ace-fca/` is tracked in git, so research documents and retros are committed with the work.
- `docs/how-we-work.md` and `docs/deployment-with-scripts.md` are untracked files in the working tree.

### 2. The application as it exists (layout, CSS, content)

Routing and rendering:

- `internal/web/web.go:47-51` registers one route, `GET /{$}`. Any other path returns 404 and other methods on `/` return the mux default (`internal/web/web_test.go` covers 404 for `/missing` and a non-GET on `/`).
- `internal/web/web.go:15-16` embeds `templates/*.html`. `NewServer` parses exactly one file, `templates/index.html` (`internal/web/web.go:36`).
- `indexData` carries `Title` and `Heading` only (`internal/web/web.go:18-21`). The handler sets `Title: "Sudhaus Engen"` and `Heading: "Hello world"` (`internal/web/web.go:56`).

Layout and CSS:

- `internal/web/templates/index.html` is a complete standalone HTML document with `<html lang="en">`, a viewport meta tag, a title, and one `<h1>`. It has no `<link>` to a stylesheet, no `<style>` block, no header, footer, or navigation, and no `{{define}}` or `{{template}}` blocks.
- There is no static file route and no `static/` directory. The repository holds no CSS, font, or image file.
- `.dockerignore` excludes everything except `.go-version`, `go.mod`, `go.sum`, `cmd`, and `internal`. A new top-level asset directory would not reach the Docker build context unless it is added to the allow list.
- The runtime image contains only the compiled binary on `ubuntu:26.04` (`Dockerfile:41-46`). Templates reach it through `go:embed`.

Content:

- No brew-day data model, data file, or event source exists. No `.ics` handler exists. `docs/adrs/` holds only ADR 0001, which lists "decide the calendar event format (separate ADR)" as follow-up work (ADR 0001, "Consequences").
- Project memory (engrim record 38) states the first-release scope as a server-rendered brew-day list or month grid plus an `.ics` feed. This is not recorded in a repository document.
- `.github/copilot-instructions.md` describes the site as rendering brew-day events plus "the legally required German pages (Impressum and Datenschutzerklarung)". No route, template, or text for either page exists.

Cookies and tracking:

- The code sets no cookies. A grep for `Set-Cookie` and `http.Cookie` finds no match in `cmd/` or `internal/`.
- The code writes structured logs to stderr with `slog` for startup, shutdown, and render errors (`cmd/sudhaus-engen/main.go:26`, `internal/web/web.go:58-65`). It has no per-request access logging.

Other notes:

- `.github/workflows/test.yml` starts a Postgres service and sets `SUDHAUS_ENGEN_POSTGRES_DSN`. No Go code reads that variable or uses a database.
- The server listens on `PORT`, default `8000` (`cmd/sudhaus-engen/main.go:17,31-34`). The Dockerfile exposes 8000 and runs as user 1000 (`Dockerfile:43-44`). No health endpoint exists.

### 3. Deployment and hosting

Decision documents:

- ADR 0001 (status Accepted, revised 2026-09-02) selects Azure Container Apps (Consumption) in West Europe, provisioned with Terraform and deployed as a Docker container. It includes ACR, Log Analytics, an Azure-managed TLS certificate, `azurerm_dns_zone` for DNS, and disclosure of Microsoft/Azure as a processor.
- `docs/deployment-with-scripts.md` (status "idea, not yet planned or implemented") records the delivery model:
  - The operator builds with `docker buildx build --platform linux/amd64`, tags with the git commit SHA, runs `az acr login`, and pushes.
  - A promote script runs `az containerapp update --image <registry>/<image>:<git-sha>`. The app runs in single-revision mode, so promotion replaces the running revision at once.
  - Rollback is a promotion of an earlier SHA.
  - Terraform owns the infrastructure, including the container app with `ignore_changes` on the image. Scripts own image delivery.
- The document lists open points: script names and arguments, whether `make` targets wrap the scripts, a clean-tree and pushed-SHA check, how the operator confirms a promotion, adding `Microsoft.ManagedIdentity` to `script/register-providers`, and image retention.

What exists and what does not:

| Item                                 | State                                                                                                 |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| Terraform prod root                  | Backend, provider, region pin, and `common_tags` only. No resources (`terraform/envs/prod/main.tf`).  |
| Remote-state bootstrap               | `script/tfstate-bootstrap` exists. Whether the live backend is provisioned was not verified.          |
| Provider registration                | `script/register-providers` registers five providers. `Microsoft.ManagedIdentity` is not in the list. |
| Azure sign-in and Terraform wrappers | `script/az-login`, `script/terraform`, and the `make az-login`, `tf-init`, `plan`, `apply` targets.   |
| Build-and-push script                | Absent.                                                                                               |
| Promote script                       | Absent.                                                                                               |
| Local image build                    | `make docker-build` runs `docker build -t sudhaus-engen .` with no platform flag and no SHA tag.      |
| Multi-arch support in the Dockerfile | Present. The build stage uses `BUILDPLATFORM`, `TARGETOS`, and `TARGETARCH` (`Dockerfile:1-5,31`).    |
| CI                                   | `build`, `lint`, and `test` workflows. `build` runs `make docker-build`. No registry push or deploy.  |
| Health endpoint                      | Absent.                                                                                               |

Logging options for the Container Apps environment (Microsoft Learn, "Log storage and monitoring options in Azure Container Apps", page dated 2026-08-18, P):

- The environment offers three log destinations: Log Analytics (the default), Azure Monitor, and "Don't save logs". With "Don't save logs", storage of log data is disabled and container output stays visible only through the real-time log stream.
- The Azure CLI value is `--logs-destination none`. In the azurerm provider (checked at tag v5.0.0), `logs_destination` and `log_analytics_workspace_id` on `azurerm_container_app_environment` are both optional. The provider documents that omitting `logs_destination` results in "logs being streamed only", and `log_analytics_workspace_id` is required only for `log-analytics`.
- The `ContainerAppHTTPLogs` table records one entry per request handled by the environment's ingress. Its `XForwardedFor` column holds the client IP chain, and the table reference says to treat it as personally identifiable information. The table exists only where a diagnostic setting sends it to a destination (Azure Monitor path); it is not written when the destination is "Don't save logs" (the inference from the two Learn pages, not a quoted statement).
- Application stdout and stderr (`slog` output) belong to the console-log category and follow the same destination setting. The application writes no per-request line and no IP address (section 2).
- ADR 0001 (decision step 1 and the follow-up list) plans a region-pinned Log Analytics workspace. The user requirement "log no user info at all" and that plan do not agree. Resolving it is a decision point (13).

### 4. Domain and TLS

- The user purchased `sudhaus-engen.de` at INWX on 2026-10-18. A DNS query shortly afterwards still returned NXDOMAIN from the `.de` zone, which is the expected answer until name servers are set at the registrar.
- ADR 0001 states that a `.de` domain needs a DENIC-accredited registrar, that Azure App Service Domains does not offer one, and that registration happens out-of-band. Only DNS hosting and the custom-domain binding belong to Terraform. `docs/deployment-with-scripts.md` lists "DNS zone and domain binding" as Terraform work "in a later change".
- ADR 0001 chooses an Azure-managed TLS certificate so that no certificate automation runs on the operator's side.
- Microsoft Learn ("Custom domain names and free managed certificates in Azure Container Apps", page dated 2026-01-28) lists these requirements for the managed certificate:
  - HTTP ingress is enabled and the app is reachable from DigiCert's validation IP addresses.
  - An apex domain needs an A record to the Container Apps environment's IP address, plus a TXT record `asuid` with the verification code. The CLI validation method for apex domains is HTTP.
  - A subdomain needs a CNAME that points directly at the app's generated domain name, plus a TXT record `asuid.<subdomain>`. An intermediate CNAME target such as Traffic Manager or Cloudflare blocks issuance and renewal.
  - If any CAA record exists on the root domain, it must include `0 issue digicert.com`.
  - The app must be in a running state during issuance and every automatic renewal, because a stopped app cannot answer the validation request.
- ADR 0001 describes scale to zero as acceptable and `min_replicas = 1` as an option. Microsoft Learn (P) says the app must be in a running state while the certificate is issued and for each automatic renewal, and that a stopped app "doesn't serve the domain validation request". The page does not say whether a scaled-to-zero app counts as running, and no other Microsoft Learn page checked (scale, revisions, ingress overview, billing) mentions certificates in connection with zero replicas. The Learn revisions page uses "inactive" only for a deactivated revision, and the billing page uses "scaled to zero replicas" for the case with no replicas, so "stopped" in the certificate page is not defined by either. The certificate page also states that failed issuance or renewal is retried periodically, and that resubmitting the managed-certificate configuration forces a new attempt.
- GitHub issue `microsoft/azure-container-apps` 1542, read through the public GitHub API, is a DigiCert announcement about multi-perspective validation and public reachability from DigiCert addresses. A Microsoft reply there says HTTP validation needs `http://{domain}/.well-known/pki-validation/fileauth.txt` to be publicly reachable. No comment checked says anything about scale to zero. An earlier search summary that claimed renewal fails at zero replicas has no primary source, so it is not used (S, unverified).
- One hypothesis is untested: the ingress layer might start a replica when the validation request arrives, in the same way as for a user request. Only an empirical test can confirm or reject it, and a test needs Azure resources, so it belongs to the implementation phase and not to research.
- Billing (Microsoft Learn billing page, P): a revision scaled to zero replicas incurs no resource charges, and a revision with a minimum replica count above zero that sits at that minimum can qualify for a reduced idle rate. Monthly free grants per subscription are the first 180,000 vCPU-seconds, 360,000 GiB-seconds, and 2 million HTTP requests. The euro rate for idle usage was not extracted.
- `script/register-providers` includes `Microsoft.Network`, which the Terraform README ties to DNS and custom-domain certificates.

#### 4.1 Where the DNS zone lives (explanation for decision point 12)

The registrar (INWX) holds the domain registration. A separate question is which servers answer DNS queries for it. There are two arrangements:

| Arrangement                 | What the operator does at INWX                                                                                            | Where records are edited                          | Terraform                                                                                                                                                   |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| INWX name servers (default) | Nothing. INWX name servers answer for the domain.                                                                         | INWX customer area, or the INWX API               | Records for Azure (A, `asuid` TXT, optional CAA) are made by hand, or with the `inwx` provider (see below).                                                 |
| Azure DNS (ADR 0001)        | Enter Azure's name servers under "Externe Nameserver" for the domain. At least two are required (INWX knowledge base, P). | Azure, through `azurerm_dns_zone` and record sets | One provider for zone, records, and certificate validation. Needs the DNS zone to exist first, because DENIC checks the name servers when they are changed. |

- INWX knowledge base (P): for `.de`, the registry checks the new name servers, and the update fails (an `UPDATE FAILED` email) when the zone does not exist yet on the new servers or is not synchronised. A changed delegation takes 3 to 48 hours to become fully active.
- INWX knowledge base (P): DNSSEC with INWX name servers is a one-click "automatic mode". With external name servers the automatic mode must not be used (the domain would become unreachable), and the operator enters the DNSKEY or DS values from the DNS host by hand.
- Azure DNS can sign a public zone with DNSSEC (Microsoft Learn, "Overview of DNSSEC" and the DNSSEC how-to, P):
  - Signing uses ECDSAP256SHA256 (algorithm 13) and NSEC for authenticated denial of existence. Azure rolls the zone signing key automatically, and the key signing key rolls only through Microsoft support. The portal does not show the DNSKEY, RRSIG, and NSEC records.
  - With a TLD parent such as `.de`, the operator adds a DS record (key tag, algorithm, digest type, digest) at the registrar. The parent zone must hold the DS record, or validation fails. The CLI is `az network dns dnssec-config create` and `show`.
  - The ARM resource type is `Microsoft.Network/dnsZones/dnssecConfigs`, and only the API version `2023-07-01-preview` is listed.
  - The azurerm provider has no DNSSEC resource. The request `hashicorp/terraform-provider-azurerm` issue 28732 was still open on 2026-09-25. A Microsoft product manager said in that issue that the DNSSEC feature is generally available even though the API version carries a preview label, and commenters report that azurerm will not adopt a preview API. The workaround named there is the AzAPI provider with an `azapi_resource` of that type and the name `default`. AzAPI would be a new provider dependency that needs an explicit decision.
  - DENIC's own FAQ (P) describes how DENIC signs the `.de` zone (RSA/SHA256, NSEC3 with opt-out). It does not list which algorithms DENIC accepts in a child DS record. A DENIC news article (P, undated, about 2015) states that DENIC accepts ECDSA algorithms 13 and 14 in submitted key material for `.de` domains (Follow-up Research 2026-10-18T19:59:47+02:00).
- Whether the operator wants DNSSEC at all is a decision (point 12). With INWX name servers, INWX offers a one-click automatic mode.
- INWX publishes a Terraform provider, `inwx/inwx` (MIT licence, GitHub repository pushed 2026-09-03). Its resources are `inwx_domain`, `inwx_domain_contact`, `inwx_nameserver`, `inwx_nameserver_record`, `inwx_glue_record`, `inwx_dnssec_key`, and `inwx_automated_dnssec`. It would be a new provider dependency, so it needs an explicit decision before use.
- ADR 0001 places registration out of band and puts only DNS hosting and the custom-domain binding in Terraform.
- A mailbox is not part of the domain purchase. The user supplied a Gmail address for the Impressum, so no mail service on `sudhaus-engen.de` is needed for the first release.

#### 4.2 Terraform support for the custom domain and managed certificate

- The azurerm provider releases `v5.x` (latest seen: v5.10.0, 2026-10-15). At tag `v5.0.0` the documentation for `azurerm_container_app_custom_domain`, `azurerm_container_app_environment_managed_certificate`, and `azurerm_container_app_environment` exists, so the `~> 5.0` pin covers them.
- `azurerm_container_app_custom_domain` supports the managed certificate. The `container_app_environment_certificate_id` argument is omitted and the `lifecycle` block needs `ignore_changes = [certificate_binding_type, container_app_environment_certificate_id]`, because Azure changes those values outside Terraform. The `asuid.` TXT record must exist before the domain is added.
- `azurerm_container_app_environment_managed_certificate` takes `subject_name` and `domain_control_validation` (`HTTP` by default, or `CNAME`) and exports `validation_token`.
- Both resources belong to the same Terraform split as the rest of the infrastructure. The scripts in `docs/deployment-with-scripts.md` only move images.

### 5. German legal requirements

Source quality is marked per item: **P** means primary text or a public authority page read during this research. **S** means a secondary summary (law-firm, chamber, or search-result summary) that was not checked against the statute text.

#### 5.1 Impressum (provider identification)

Three rules can apply. They overlap and the operator's status decides which ones bind this site. The operator states that the site is non-commercial and run by Joshua Moody as a private person, so § 18 Abs. 1 MStV is the likely basis and § 5 DDG likely does not apply. A lawyer has not confirmed this reading.

| Rule             | Applies to                                                                               | Source |
| ---------------- | ---------------------------------------------------------------------------------------- | ------ |
| § 5 DDG          | Digital services that are "geschäftsmäßig" and normally offered for payment              | P      |
| § 18 Abs. 1 MStV | Telemedia that do not serve exclusively personal or family purposes                      | P      |
| § 18 Abs. 2 MStV | Journalistic-editorial offerings, which also need a named person responsible for content | P      |

- The Medienanstalt Hessen defines "geschäftsmäßig" as a sustained, long-running offering, regardless of any intent to profit. It reads "in der Regel gegen Entgelt" as covering a site run to present a business, promote goods or services, or win customers.
- Fines for a missing Impressum reach EUR 50,000 (Medienanstalt Hessen).
- Required content under § 5 DDG (statute text for the numbered items, authority page for the summary):
  - Natural person: first and last name (no pseudonym) and a postal address that a court can serve (no P.O. box).
  - Legal person: name, legal form, address of the establishment, and the authorised representative.
  - Contact: an email address plus one more way to reach the provider quickly and directly, for example a telephone number, fax number, or contact form.
  - Supervisory authority, only when the activity needs official permission.
  - Commercial register and number, only when registered.
  - VAT identification number or economic identification number, only when held (§ 5 Nr. 6 DDG).
- The Impressum must be easy to recognise, directly reachable, and permanently available. The Medienanstalt Hessen describes this as the "2-click rule", with a link named "Impressum" or "Kontakt".
- The authority page describes a c/o address of an authorised recipient as an accepted way to avoid showing a private address. That page presents it in the context of influencers and says the authority may ask for a signed receipt confirmation.
- A site that is purely private or family-only needs no Impressum, but the Medienanstalt guidance and the secondary sources describe this boundary as narrow (S).
- Text of § 18 MStV, read from the Sächsische Landesmedienanstalt excerpt (P):
  - Abs. 1: providers of telemedia that do not serve exclusively personal or family purposes must keep "leicht erkennbar, unmittelbar erreichbar und ständig verfügbar" (1) name and address, and (2) for legal persons, also the name and address of the authorised representative.
  - Abs. 2: journalistic-editorial offerings, which in particular reproduce content of periodical print products, must name a person responsible, with name and address, in addition to the duties of § 5 DDG. That person must have a permanent residence in Germany, must not have lost the capacity to hold public office, and must be fully legally capable and subject to unrestricted criminal prosecution. Abs. 4 applies § 5 DDG to these offerings.
- Content for this site under the chosen basis: first and last name of Joshua Moody and a postal address that a court can serve. The user supplied a Gmail address for contact and the operator's home address in Engen (78234), with the full street spelling confirmed. No second contact channel was supplied.
- Under § 18 Abs. 1 MStV an email address and a second channel are not statutory items. They are statutory under § 5 Nr. 2 DDG. Whether to publish the § 5 DDG item set anyway is a planning decision (decision point 2).
- A brewing calendar that lists dates does not read as a journalistic-editorial offering. If the site later carries editorial articles, § 18 Abs. 2 would add the responsible-person line. The operator, living in Baden-Württemberg, would meet the residence condition.

#### 5.2 Datenschutzerklärung (privacy notice)

- Art. 12 and Art. 13 DSGVO require an intelligible notice at the time the data is collected. Art. 13(1) and (2) (gdpr-info.eu text, P) list: the controller's identity and contact, the data protection officer if one exists, purposes and legal basis, the legitimate interests when Art. 6(1)(f) is the basis, recipients, third-country transfers and the safeguard used, the retention period or its criteria, data-subject rights, the right to complain to a supervisory authority, whether providing data is required, and automated decision-making.
- A web server necessarily receives the visitor's IP address in order to answer. The notice for this site must still describe that processing, even when nothing is stored. The LG München I reasoning (5.4) treats a dynamic IP address as personal data (P).
- The controller is Joshua Moody. The competent supervisory authority follows the controller's seat in Baden-Württemberg: the Landesbeauftragte für den Datenschutz und die Informationsfreiheit Baden-Württemberg, Heilbronner Straße 35, 70191 Stuttgart (postal: Postfach 10 29 32, 70025 Stuttgart), telephone 0711/615541-0 (P, the authority's Impressum page). A private person with no employees normally needs no data protection officer (the threshold was not researched).
- The hosting processor must be named. ADR 0001 already plans to name Microsoft/Azure (West Europe) and to rely on the Microsoft DPA and Standard Contractual Clauses.
- For transfers to Microsoft as a US company, the EU-US Data Privacy Framework adequacy decision is a second basis. The EU General Court dismissed the annulment action in Latombe v Commission (T-553/23) on 2025-09-03. A further appeal to the Court of Justice remained possible when that judgment was reported (S, with the Court's press release among the cited sources).
- Logging: the operator wants Log Analytics and requires that the logs hold no personal data. Section 3 shows that the application writes no request data and that request-level IP logging (`ContainerAppHTTPLogs`, whose `XForwardedFor` column Microsoft says to treat as personally identifiable information) is a separate opt-in. With a workspace, the notice must state its retention period (a Terraform setting on `azurerm_log_analytics_workspace`) and can say that the stored logs contain no personal data.
- Microsoft's own processing, from the Microsoft Products and Services DPA (English, last updated 2026-05-22, P, downloaded as a Word document from the Microsoft licensing site):
  - Personal Data under the DPA includes data "generated, derived or collected by Microsoft", including data sent to Microsoft as a result of using service-based capabilities. Pseudonymised identifiers count as Personal Data, and the data categories list names IP addresses.
  - Under "Processing for Business Operations Incident to Providing the Products and Services", Microsoft may aggregate statistics from pseudonymised identifiers (for example usage logs) without accessing content. The listed purposes are billing and account management, compensation, internal reporting and business modelling, and financial reporting. Data minimisation applies, and profiling and advertising are excluded.
  - For GDPR Personal Data used for those business operations, Microsoft states that it acts as an independent data controller and makes the Additional Safeguards commitments.
  - The DPA gives no retention period for this data. Its retention clause covers Customer Data stored in Online Services (90 days in a limited-function account after termination, then deletion within 90 more days).
- What this means for the notice: even when the operator stores no logs, Microsoft may process technical request data as a controller for its own business operations. The notice should name Microsoft as the hosting provider and as an independent controller for that processing, and should refer to the Microsoft DPA. A claim that "nothing is processed at all" would not match the DPA. The exact retention period for Microsoft's own data was not found.
- A search summary said Microsoft is a controller for "Service Generated Data". The May 2026 DPA does not use that phrase, so the notice must not cite it.

#### 5.3 Cookies and device storage (TDDDG § 25)

- The consent rule in § 25 TDDDG (formerly TTDSG) covers storing or reading information on the visitor's device. Consent is not needed when the access is strictly necessary to provide a service that the user explicitly requested (P, statute text at gesetze-im-internet.de, whose URL still uses the `ttdsg` path).
- The application sets no cookies today (section 2). A notice that states no cookies or tracking tools are used suffices for a site in that state (S).

#### 5.4 Third-party resources loaded by the page

- LG München I, judgment of 2022-01-20, case 3 O 17493/20 (P, Bavarian state law portal, which gives the full operative part and reasons): the website operator passed the visitor's dynamic IP address to Google by loading Google Fonts, without consent. The court held the dynamic IP address to be personal data, found no legitimate interest under Art. 6(1)(f) DSGVO because Google Fonts "can also be used without a connection to a Google server", ordered the operator to stop (with a penalty of up to EUR 250,000 per breach), and awarded EUR 100 in damages under Art. 82 DSGVO.
- The same reasoning applies to any resource fetched from a third-party host at page load, for example CDNs, fonts, map tiles, and embedded media.
- The current template loads no third-party resource.
- The user will use public-domain fonts and has no images. Fonts served from the site's own host keep the visitor's IP address on the operator's server. That needs a static-file route and an update to the `.dockerignore` allow list, or `go:embed` of the font files (section 2).
- Fonts that are labelled public domain are uncommon. Many free fonts carry the SIL Open Font License, which allows self-hosting but has its own conditions. The licence of each chosen font file was not checked and is left to the planning and content work.

#### 5.5 Accessibility (BFSG)

- The Barrierefreiheitsstärkungsgesetz applies from 2025-06-28. Under § 3 Abs. 3 BFSG, the accessibility duty "gilt nicht für Kleinstunternehmen, die Dienstleistungen anbieten oder erbringen" (P, statute text).
- A micro-enterprise has fewer than 10 employees and at most EUR 2 million annual turnover or balance sheet total (S).
- The duty for services targets e-commerce services for consumers, such as shops and booking systems. Summaries describe a read-only event calendar with no contract or booking as outside that scope (S).
- The site as described offers no purchase or booking, and the operator is a private person with no employees.

#### 5.6 Consumer dispute resolution notice

- Regulation (EU) 2024/3228 of 2024-12-19 (EUR-Lex, P) repeals Regulation (EU) No 524/2013 "with effect from 20 July 2025" (Art. 1), shuts down the online dispute resolution platform (Art. 2(1)), and stopped complaint submission on 2025-03-20 (Art. 2(2)). Recital 3 names the duty to give "a link to the OS platform" that the repeal removes. Secondary sources add that a leftover OS link risks a warning letter for misleading information (S). A related recital says that three directives with references to the platform will be amended by a separate act, which was not checked.
- § 36 VSBG (P, statute text):
  - Abs. 1 applies to "Ein Unternehmer, der eine Webseite unterhält oder Allgemeine Geschäftsbedingungen verwendet". It requires information on willingness or duty to join a consumer arbitration board (Nr. 1) and, if the trader is committed or obliged, the competent board with address, website, and a participation statement (Nr. 2).
  - Abs. 3 exempts a trader who employed ten or fewer persons on 31 December of the previous year from the Nr. 1 duty.
  - A non-commercial private operator is probably not a "Unternehmer" at all (the definition in § 14 BGB was not read), the operator has no employees, and no arbitration commitment exists. The notice is therefore not expected for this site, and no OS-platform link is needed.

#### 5.7 Language and navigation

- Art. 12 DSGVO requires the privacy notice in a form that is intelligible. The research found no statutory rule that fixes German as the language of a site. The current template declares `lang="en"` and English-language placeholder text.
- The Impressum and the privacy notice must be reachable from every page. The current site has one page and no footer.

#### 5.8 Operator duties for a small public site

Added in Follow-up Research 2026-10-18T19:59:47+02:00. Statute text is P. The application to this site is my reading and no lawyer has checked it.

- Household exemption: Art. 2(2)(c) DSGVO excludes processing "by a natural person in the course of a purely personal or household activity". The CJEU read this narrowly. In Lindqvist (C-101/01) the Court held that publishing personal data on the internet, where it is accessible to an indefinite number of people, is not a private or family activity (EUR-Lex summary, P). The Ryneš press release (C-212/13, 2014-12-11, P) states that the exemption "must be narrowly construed". A public website, even a hobby site, is therefore inside the DSGVO.
- Data protection officer: § 38 Abs. 1 BDSG requires one "soweit sie in der Regel mindestens 20 Personen ständig mit der automatisierten Verarbeitung personenbezogener Daten beschäftigen" (P, statute text). Art. 37(1)(b) and (c) DSGVO apply only to core activities of large-scale monitoring or large-scale special-category data (P). A single operator meets neither rule. The notice can say that no data protection officer is appointed.
- Records of processing: Art. 30(5) DSGVO exempts an organisation with fewer than 250 persons "unless the processing it carries out is likely to result in a risk to the rights and freedoms of data subjects, the processing is not occasional, or the processing includes special categories of data" (P). The DSK Kurzpapier Nr. 1 (2018-12-17, P) lists "nicht nur gelegentlich" processing as a reason the exemption is lost and says that a record will "vielfach" be necessary. A site that runs permanently does not process occasionally, so the cautious reading is that a short internal record is needed. It is not published, and the supervisory authority can ask for it (Art. 30(4)). It is a few lines for this site (decision point 18).
- Right to object: when Art. 6(1)(f) is the legal basis, Art. 21(4) requires that the right "shall be explicitly brought to the attention of the data subject and shall be presented clearly and separately from any other information" (P). The notice needs a separate, visibly set apart paragraph on the right to object.
- Cookie banner: the DSK "Orientierungshilfe für Anbieter:innen von digitalen Diensten" (Version 1.2, November 2024, 36 pages, P) covers § 25 TDDDG, which applies to storing or reading information on the visitor's device. It states that access to the Impressum and the Datenschutzerklärung must not be blocked by a banner. I did not find a sentence that says a site without cookies needs no banner. The conclusion rests on the scope of § 25 (5.3) and is a reading, not a quoted statement.
- Server access data: the Orientierungshilfe does not discuss server access logs as a legal-basis case. Art. 6(1)(f) as the basis for answering web requests is therefore my reading and is not confirmed by an authority text in this research (S).
- Email contact: the DSK press release of 2020-05-26 (P, read from a PDF copy at a state authority; the URL was not recorded) says that transport encryption is a minimum measure for controllers who send email with personal data, and that end-to-end encryption is needed at high risk. It concerns sending. I found no authority text that requires a particular sentence about receiving mail at a private provider. A short paragraph that names the email provider is common practice (S, unverified).
- LfDI Baden-Württemberg offers an online generator, "DS-GVO.clever" (<https://www.baden-wuerttemberg.datenschutz.de/ds-gvo.clever/>). The page exists but needs JavaScript and I did not read its output. A search summary says it targets associations and small businesses (S).
- Mapping of the Art. 13 items to this site (Art. 13 text P, application is my reading):

| Art. 13 item                    | For this site                                                                                      |
| ------------------------------- | -------------------------------------------------------------------------------------------------- |
| Controller identity and contact | Name, address, and email as in the Impressum                                                       |
| Data protection officer         | None appointed (no obligation, see above)                                                          |
| Purposes and legal basis        | Operating the site and answering requests, Art. 6(1)(f); handling email, Art. 6(1)(f) or (b)       |
| Legitimate interest named       | Reliable and secure delivery of the site (Art. 13(1)(d))                                           |
| Recipients                      | Microsoft as host (processor, and independent controller for its own purposes), the email provider |
| Third-country transfer          | Microsoft as a US company, Data Privacy Framework and Standard Contractual Clauses (5.2)           |
| Retention                       | Workspace retention period set in Terraform, and how long emails are kept (operator's choice)      |
| Rights                          | Access, rectification, erasure, restriction, portability, and a separate paragraph on objection    |
| Complaint                       | LfDI Baden-Württemberg (5.2)                                                                       |
| Provision required              | Not required, but a request needs the IP address to be answered                                    |
| Automated decision-making       | None                                                                                               |

### 6. Pages the repository already calls required

- `.github/copilot-instructions.md` and ADR 0001 both name the Impressum and the Datenschutzerklärung as legally required pages of the site.
- ADR 0001 lists "author the Datenschutzerklarung processor disclosure" as follow-up work.

## Decision Points Identified

The following decisions will need to be made during planning:

1. **Operator status and Impressum basis**: The operator answered that the site is non-commercial and run by Joshua Moody as a private person in Baden-Württemberg, and then chose § 18 Abs. 1 MStV (name and address) as the basis (alternative A below).
   - Alternative A: Publish only the § 18 Abs. 1 MStV items (name, postal address).
   - Alternative B: Publish the fuller § 5 DDG item set (name, address, email, second channel) as a precaution, which also covers a later move toward commercial activity.
   - Key factors: the fine for a missing Impressum is up to EUR 50,000, the Medienanstalt reading of "geschäftsmäßig" ignores profit intent, and a lawyer has not confirmed the reading.

2. **Contact channel in the Impressum**: The user supplied one email address (a Gmail address) and asked whether a second channel is required. It is not required under § 18 Abs. 1 MStV, the likely basis. Under § 5 DDG, if it applied, the second channel may be a telephone number, a fax number, or a contact form, so a telephone number is not the only way (section 5.1).
   - Alternative A: Email only, which meets § 18 Abs. 1 MStV.
   - Alternative B: Add a telephone number, which meets the § 5 Nr. 2 DDG pairing.
   - Alternative C: Add a contact form served by this application (adds a form, a processing step, and privacy text, which conflicts with the no-logging goal).
   - Key factors: decision 1, and the use of a personal Gmail address in a public Impressum.

3. **Public hostname shape**: Apex, subdomain, or both.
   - Alternative A: Apex domain, which needs an A record to the environment IP.
   - Alternative B: `www` subdomain, which needs a CNAME directly to the app's generated name.
   - Key factors: managed-certificate validation differs for each, a CAA record would need `digicert.com`, and the Container Apps ingress has no host redirect, so redirecting one name to the other needs code in the Go handler (Follow-up Research 2026-10-18T19:59:47+02:00).

4. **Scale-to-zero versus certificate renewal**: The operator chose `min_replicas = 1` (alternative B). ADR 0001 accepts `min_replicas = 0`, so the ADR needs an amendment (`adr-author`). Microsoft requires the app to be running for issuance and renewal, and does not say whether a scaled-to-zero app qualifies. GitHub issue 1542 and the other Learn pages checked do not answer it either. The choice follows the documented wording and does not rest on a proven failure at zero replicas.
   - Alternative A: Keep scale to zero and test it (issue the certificate with the app idle, then watch renewal). Failed renewals are retried, and resubmitting the managed-certificate configuration forces a new attempt. Not chosen.
   - Alternative B (chosen): Set `min_replicas = 1`, which follows the documented wording and removes the question and the cold start. A replica that meets the idle conditions is billed at a reduced idle rate, and the free monthly grants apply (section 4).
   - Key factors: idle cost, cold-start latency, certificate expiry risk, and the ADR 0001 amendment.

5. **Stylesheet and asset delivery**: How CSS, fonts, and images reach the browser.
   - Alternative A: One hand-written stylesheet served from embedded files.
   - Alternative B: A build step that generates CSS.
   - Key factors: no new dependencies without checking `go.mod`, third-party hosts risk the IP-transfer finding in 5.4, `.dockerignore` allow list, and fonts (self-hosted or system stack).

6. **Page structure**: Shared base template with header, footer, and navigation, versus per-page documents.
   - Key factors: the footer must carry the Impressum and Datenschutz links on every page, `html/template` handles composition, and `lang` should match the content language.

7. **Event data source and format**: Where brew-day events live and how the `.ics` feed is produced.
   - Alternative A: A data file embedded in the binary.
   - Alternative B: A database (the test workflow already starts Postgres, but no code uses it).
   - Key factors: ADR 0001 calls for a separate ADR on the event format, and the first release is described as a list or month grid plus `.ics`.

8. **Calendar presentation**: List versus month grid for the first release.
   - Key factors: layout complexity, small-screen behaviour, and how the page reads without JavaScript.

9. **Delivery script shape**: The open points in `docs/deployment-with-scripts.md` (names, `make` wrappers, clean-tree check, promotion confirmation, image retention, health endpoint, `Microsoft.ManagedIdentity`).

10. **First-launch ordering**: The documents imply this chain, and planning decides what runs in parallel.
    - Terraform resources, then image build and push, then promote, then DNS delegation (the domain is already purchased), then custom-domain binding, then managed certificate issuance.
    - Legal pages and content are independent of the infrastructure chain but must exist before the site is public.

11. **Issue structure**: Whether the work forms one epic with batches per area (legal pages, layout and style, content, deployment, domain and TLS) or several top-level batches, per the rules in `docs/how-we-work.md`.

12. **DNS host for `sudhaus-engen.de`**: Section 4.1 explains the two arrangements. The operator expects Azure DNS, which agrees with ADR 0001 (alternative B). Today the INWX name servers answer, because no delegation to Azure exists yet.
    - Alternative A: Keep INWX name servers and create the Azure records (A or CNAME, `asuid` TXT, optional CAA) at INWX, by hand or with the `inwx` Terraform provider.
    - Alternative B: Delegate to Azure DNS as ADR 0001 states, with `azurerm_dns_zone` and Terraform-managed records. The zone must exist before the delegation, because DENIC checks the name servers.
    - Key factors: ADR 0001, one tool for zone and certificate validation, a new provider dependency under A, a 3 to 48 hour delegation delay, and the DNSSEC handling at INWX for external name servers.
    - DNSSEC (section 4.1): with INWX name servers it is one click. With Azure DNS it is supported, but Terraform needs the AzAPI provider (a new dependency) or a manual `az network dns dnssec-config create` step, and the operator then enters the DS record at INWX. DENIC accepts algorithm 13 (an undated DENIC news article, P), so the choice is not blocked by the registry. The INWX knowledge base names no algorithm restriction.

13. **Platform logging versus ADR 0001**: The operator wants Log Analytics and requires that no personal data is logged. This is alternative B below, with the app and platform logs kept free of personal data.
    - Alternative A: Omit `logs_destination` on the environment ("logs streamed only", no stored logs). Not chosen.
    - Alternative B (chosen): Keep a workspace without the `ContainerAppHTTPLogs` category and with an explicit retention. Console logs of the app are stored, so the application must write no request data.
    - Key factors: the no-personal-data rule depends on code review, debugging ability, the retention statement in the Datenschutzerklärung, and a check that the workspace holds no `ContainerAppHTTPLogs` rows.

14. **Postal address in the Impressum**: § 18 Abs. 1 MStV needs an address that a court can serve. The user supplied the operator's home address in Engen (78234) with the full street spelling confirmed.
    - Alternative A: The operator's home address (the supplied address).
    - Alternative B: A c/o address of an authorised recipient, which the Medienanstalt Hessen page allows in some cases and may ask to be backed by a receipt confirmation.
    - Key factors: privacy of the operator, and the guidance describes the c/o option in the context of influencers.

15. **Fonts and static assets**: The user will use public-domain fonts and has no images.
    - Alternative A: Self-hosted font files embedded with `go:embed`.
    - Alternative B: A system font stack with no font files.
    - Key factors: the static route, the `.dockerignore` allow list, and the third-party-request finding in 5.4. The operator does not want font licences checked, so the licence of each font stays unverified.

16. **Calendar time representation and `.ics` writer**: Whether events are all-day dates or timed, and how the feed is written (decision point 7 covers the data source).
    - Alternative A: All-day events only (`DTSTART;VALUE=DATE`), which needs no time zone definition.
    - Alternative B: Timed events in UTC (`Z` suffix), which need no VTIMEZONE. The writer converts each Berlin local start time to UTC and clients show it in the viewer's zone.
    - Alternative C: Timed events with `TZID=Europe/Berlin` and a hand-written VTIMEZONE block, which RFC 5545 requires for each TZID.
    - Writer: hand-written with the standard library (no new dependency) or `arran4/golang-ical` (new dependency, no automatic VTIMEZONE). Neither library derives VTIMEZONE rules from Go's tzdata.
    - Key factors: whether brew-days carry a start time, the no-new-dependencies rule, and the ADR on the event format that ADR 0001 calls for (Follow-up Research 2026-10-18T19:59:47+02:00, section on iCalendar).

17. **Security headers and server timeouts**: Which response headers and `http.Server` limits the first release sets.
    - Alternative A: The minimal header set (HSTS, CSP `default-src 'self'; frame-ancestors 'none'`, `nosniff`, Referrer-Policy, Permissions-Policy) and explicit `ReadTimeout`, `WriteTimeout`, `IdleTimeout` in `cmd/sudhaus-engen/main.go`.
    - Alternative B: Only the current state (`ReadHeaderTimeout` of 5 seconds, no headers).
    - HSTS `preload` is a separate sub-decision because removal from the preload list is slow.
    - Key factors: self-hosted fonts and no JavaScript fit a strict CSP, and the ingress adds no HSTS header.

18. **Records of processing and `security.txt`**: Two optional documents.
    - Records of processing (Art. 30 DSGVO): a short internal document, not a site page. The exemption in Art. 30(5) is lost for processing that is "not occasional" (section 5.8), so the cautious choice is to keep a short record.
    - `security.txt` (RFC 9116): needs `Contact` and `Expires`, and publishes a contact address. It is a policy choice with no legal duty.
    - Key factors: the operator's privacy, the effort of a yearly `Expires` update, and the no-lawyer decision.

19. **Health probe and hostname redirect**: Whether to add a health endpoint and an apex or `www` redirect in the handler.
    - Container Apps adds default TCP probes when ingress is enabled, so a probe is not required with `min_replicas = 1`. An HTTP probe gives a better signal (decision point 9 lists the health endpoint as open).
    - The redirect follows decision point 3.
    - Key factors: one more route and its tests, versus the weaker TCP probe signal.

## References

- `docs/how-we-work.md` - Epic, Batch, Task definitions and rules.
- `docs/deployment-with-scripts.md` - Script-based delivery decision, steps, rollback, and open points.
- `docs/adrs/0001-host-on-azure-container-apps-in-west-europe-with-terraform-and-docker.md` - Hosting decision, domain registration note, processor disclosure, follow-up work.
- `internal/web/web.go:15-21,36,47-65` - Embedded templates, single route, index handler.
- `internal/web/templates/index.html` - Only template; `lang="en"`, no stylesheet.
- `internal/web/web_test.go` - Tests for front page, unknown path, non-GET method.
- `cmd/sudhaus-engen/main.go:17-61` - Port, logger, server timeouts, graceful shutdown.
- `Dockerfile`, `.dockerignore` - Multi-stage build and build-context allow list.
- `Makefile` - `docker-build`, `docker-run`, `az-login`, `tf-init`, `plan`, `apply`, `review`.
- `terraform/envs/prod/main.tf`, `terraform/README.md` - Prod root with no workload resources, provider list, region pin.
- `script/register-providers` - Five registered providers.
- `.github/workflows/build.yml`, `.github/workflows/test.yml` - CI steps, Postgres service.
- <https://www.gesetze-im-internet.de/ddg/__5.html> - § 5 DDG, numbered content items (P).
- <https://www.medienanstalt-hessen.de/aufsicht/telemedien-digitale-dienste-internetaufsicht/impressumspflicht/> - Impressum duty, scope, content, fine, c/o option (P).
- <https://www.gesetze-im-internet.de/bfsg/__3.html> - § 3 Abs. 3 BFSG micro-enterprise exemption (P).
- <https://slm-online.de/zulassung-und-aufsicht/zulassung/unsichtbar-2/> - § 18 MStV excerpt (P, hosted by a state media authority).
- <https://www.gesetze-im-internet.de/vsbg/__36.html> - § 36 VSBG (P).
- <https://eur-lex.europa.eu/legal-content/DE/TXT/?uri=CELEX:32024R3228> - Regulation (EU) 2024/3228, repeal of the OS platform (P).
- <https://www.gesetze-bayern.de/Content/Document/Y-300-Z-BECKRS-B-2022-N-612> - LG München I, 3 O 17493/20 (P).
- <https://www.baden-wuerttemberg.datenschutz.de/impressum/> - Supervisory authority address for Baden-Württemberg (P).
- <https://learn.microsoft.com/en-us/azure/container-apps/custom-domains-managed-certificates> - Managed certificate requirements (P).
- <https://learn.microsoft.com/en-us/azure/container-apps/log-options> - Log destinations, including "Don't save logs" (P).
- <https://learn.microsoft.com/en-us/azure/azure-monitor/reference/tables/containerapphttplogs> - Ingress request log with `XForwardedFor` (P).
- <https://kb.inwx.com/de-de/3-nameserver/100-wie-kann-ich-externe-nameserver-eintragen> and <https://kb.inwx.com/de-de/3-nameserver/131-wie-richte-ich-dnssec-fur-meine-domain-ein> - INWX external name servers and DNSSEC (P).
- <https://github.com/inwx/terraform-provider-inwx> - INWX Terraform provider, MIT (P).
- azurerm provider documentation at tag `v5.0.0` for `azurerm_container_app_environment`, `azurerm_container_app_custom_domain`, and `azurerm_container_app_environment_managed_certificate` (P).
- <https://learn.microsoft.com/en-us/azure/container-apps/billing> - Idle versus active billing, scale to zero, and monthly free grants (P).
- <https://learn.microsoft.com/en-us/azure/dns/dnssec> and <https://learn.microsoft.com/en-us/azure/dns/dnssec-how-to> - Azure DNS DNSSEC overview and signing steps (P).
- <https://learn.microsoft.com/en-us/azure/templates/microsoft.network/dnszones/dnssecconfigs> - ARM resource `dnssecConfigs`, API version `2023-07-01-preview` (P).
- <https://github.com/hashicorp/terraform-provider-azurerm/issues/28732> - azurerm request for DNSSEC support, open on 2026-09-25 (P for the issue text, comments are opinion).
- <https://github.com/microsoft/azure-container-apps/issues/1542> - DigiCert validation announcement, HTTP validation path (P).
- <https://www.denic.de/en/faq/faqs-about-dnssec/> - How DENIC signs the `.de` zone (P).
- <https://www.denic.de/news/news-archiv/article/unterstuetzung-weiterer-krypto-algorithmen-fuer-dnssec-domains-unter-de/> - DENIC accepts ECDSA algorithms 13 and 14 for `.de` domains (P, undated).
- <https://www.iana.org/assignments/dns-sec-alg-numbers/dns-sec-alg-numbers.xhtml> - Algorithm 13 status in the IANA registry (P).
- <https://www.rfc-editor.org/rfc/rfc5545.txt> and <https://www.rfc-editor.org/rfc/rfc7986.txt> - iCalendar and its extension properties (P).
- <https://github.com/arran4/golang-ical> and <https://github.com/emersion/go-ical> - Go iCalendar libraries (P).
- <https://pkg.go.dev/time/tzdata> - Embedded time zone database, about 450 KB (P).
- <https://www.w3.org/WAI/ARIA/apg/patterns/table/> and <https://www.w3.org/WAI/ARIA/apg/patterns/grid/> - Native table versus interactive grid (P).
- <https://learn.microsoft.com/en-us/azure/container-apps/ingress-overview> and <https://learn.microsoft.com/en-us/azure/container-apps/ingress-how-to> - HTTP-to-HTTPS redirect, `allowInsecure`, forwarded headers (P).
- <https://learn.microsoft.com/en-us/azure/container-apps/health-probes> - Default probes (P).
- <https://learn.microsoft.com/en-us/azure/container-apps/rule-based-routing> - Path-based routing only (P).
- <https://www.rfc-editor.org/rfc/rfc9116.html> - `security.txt` (P).
- <https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html> - Security header guidance (S, fetched).
- <https://www.gesetze-im-internet.de/bdsg_2018/__38.html> - § 38 BDSG data protection officer threshold (P).
- <https://gdpr-info.eu/art-2-gdpr/>, <https://gdpr-info.eu/art-21-gdpr/>, <https://gdpr-info.eu/art-30-gdpr/>, <https://gdpr-info.eu/art-37-gdpr/> - Art. 2, 21, 30, 37 DSGVO text (P).
- <https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:62001CJ0101> - CJEU Lindqvist C-101/01, EUR-Lex summary (P).
- <https://www.lda.brandenburg.de/sixcms/media.php/9/OH_Digitale_Dienste.pdf> - DSK Orientierungshilfe Digitale Dienste, Version 1.2 (P).
- <https://www.datenschutzkonferenz-online.de/media/kp/dsk_kpnr_1.pdf> - DSK Kurzpapier Nr. 1, records of processing (P).
- <https://www.microsoft.com/licensing/docs/documents/download/MicrosoftProductandServicesDPA(WW)(English)(May2026)(CR).docx> - Microsoft Products and Services DPA, May 2026 (P).
- Secondary summaries (S), not checked against statute or judgment text: the OS-platform warning-letter risk, the BFSG micro-enterprise definition and scope, Latombe v Commission T-553/23 (press release at <https://curia.europa.eu/jcms/upload/docs/application/pdf/2025-09/cp250106en.pdf>), the claim that scale-to-zero breaks renewal (no primary source found) and the claim that Microsoft is a controller for "Service Generated Data" (not in the May 2026 DPA).

## Historical Context

- ADR 0001 was rewritten in place on 2026-09-02 from an Azure VM decision to Azure Container Apps, before any infrastructure existed. The VM option remains documented as alternative A.
- The ADR names Microsoft's US parent as a residual lawful-access concern that disclosure, not architecture, addresses.
- `docs/deployment-with-scripts.md` was written on 2026-10-18 and builds on ADR 0001.
- No earlier research or plan documents exist. This is research document 0001.

## Related Documentation

- `.github/ace-fca/README.md` - ACE-FCA phase workflow that each task follows.
- `.github/instructions/terraform.instructions.md`, `.github/instructions/bash.instructions.md`, `.github/instructions/go.instructions.md` - Style rules for the infrastructure, script, and Go work in this area.
- `.github/skills/adr-author/SKILL.md` - Skill for the event-format ADR and any new hosting ADR.

## Open Questions

Answered by the operator on 2026-10-18: the site is non-commercial, the operator is Joshua Moody (a private person), the seat is Baden-Württemberg, the registrar is INWX, the contact email is a Gmail address, no user information is logged, no images are used yet, and the fonts are public domain.

Answered by the operator on 2026-10-18 (second round): the postal address is the operator's home address in Engen (78234) with the full street spelling confirmed; the Impressum basis is § 18 Abs. 1 MStV; the operator expects Azure DNS; font licences are not to be checked; and no lawyer will review the legal reading.

Answered by research (see Follow-up Research below): the azurerm support for the custom domain and managed certificate, the platform logging options, the INWX name-server and DNSSEC options, the scope of § 36 VSBG, the OS platform repeal, the LG München ruling text, the § 18 MStV text, the § 25 TDDDG text, the Baden-Württemberg supervisory authority, how Microsoft processes request data under the DPA, and whether Azure DNS offers DNSSEC.

Still open:

- Does the operator want DNSSEC (decision point 12)? The DNS host is expected to be Azure DNS, and DENIC accepts the Azure signing algorithm.
- Sector-specific rules for the subject matter of the site (brewing tax and customs rules were excluded at the user's request).

Accepted as unverified by the operator's choice: the licence of each font file (5.4), the legal reading in section 5 (no lawyer will check it), and Microsoft's retention period for its own request data, which the operator assumes is compliant.

Gaps that remain after the 2026-10-18T19:59:47+02:00 follow-up (none blocks planning): the subscription and refresh behaviour of Apple, Google, and Outlook calendars for a URL feed, the DIN 5008 and Duden rules for writing German dates, an authority text for Art. 6(1)(f) as the basis for server access data, an authority text on a banner-free site, and a current dated DENIC list of accepted algorithms.

## Follow-up Research [2026-10-18T13:33:47+02:00]

Triggered by the operator's answers to the open questions. The answers are recorded in Open Questions above.

- Verified against primary text: § 18 MStV, § 25 TDDDG, § 36 VSBG, Art. 13 DSGVO, Regulation (EU) 2024/3228, and the LG München I judgment. Section 5 now marks these as P.
- Corrected a date in the Summary: the OS platform repeal takes effect on 2025-07-20, not 2026-07-20.
- Added the Container Apps logging findings (section 3), the DNS and INWX explanation (section 4.1), and the azurerm support check (section 4.2).
- Added decision points 12 to 15 (DNS host, platform logging versus ADR 0001, postal address, fonts and static assets) and revised points 1, 2, and 4.
- Not resolved by research: scale-to-zero versus renewal, Microsoft's retention of request data without stored logs, DNSSEC through Azure DNS, and font licences.

## Follow-up Research [2026-10-18T13:48:29+02:00]

Triggered by the operator's request to resolve the three researchable open items.

- Scale-to-zero versus managed-certificate renewal: still undocumented. Learn says "running" and "stopped" and does not define either against zero replicas. GitHub issue 1542 covers validation reachability and says nothing on zero replicas. Added the billing rules for zero replicas and for idle replicas (section 4) and a note that a test is implementation work. Decision point 4 now says `min_replicas = 1` follows the documented wording.
- Microsoft's processing of request data: read the May 2026 DPA. Microsoft acts as an independent controller for business-operations processing, the data categories include IP addresses, and no retention period is given for that data. Section 5.2 now says how the notice has to describe this.
- Azure DNS DNSSEC: supported, with a preview-labelled ARM API and no azurerm resource. Terraform needs AzAPI or a manual step. Section 4.1 and decision point 12 record this. The DENIC acceptance of algorithm 13 in a DS record was not confirmed from a primary source.
- Corrected one claim: a search summary said Microsoft is a controller for "Service Generated Data". The DPA does not use that phrase.
- Not resolved by research: the empirical scale-to-zero result, Microsoft's retention period, DENIC acceptance of algorithm 13, font licences, and the lawyer check.

## Follow-up Research [2026-10-18T13:57:25+02:00]

Triggered by the operator's second round of answers and the confirmation of the street spelling and the Impressum basis.

- Postal address: supplied (home address in Engen, 78234), and the operator confirmed the full street spelling. The address is not copied into this document.
- Impressum basis: the operator chose § 18 Abs. 1 MStV. Name, postal address, and the supplied email address then form the Impressum, and no second contact channel is needed. Decision points 1 and 2 record this.
- Second contact channel: not required under § 18 Abs. 1 MStV. Under § 5 DDG, if it applied, a contact form or fax number would also qualify, not only a telephone number. Decision point 2 records this.
- DNS host: the operator expects Azure DNS, which is what ADR 0001 says. The INWX name servers answer only until a delegation to Azure is set. Decision point 12 records this, and DNSSEC stays open.
- Font licences and the lawyer check: the operator declined both. Both are recorded as accepted and unverified.

## Follow-up Research [2026-10-18T14:01:06+02:00]

- Microsoft's retention period: the operator directed that it be assumed compliant. It is recorded as accepted and unverified, and the privacy notice still names Microsoft as an independent controller (section 5.2).
- Scale to zero: the operator chose `min_replicas = 1`. Whether a scaled-to-zero app would renew the certificate stays undocumented and untested, and the choice makes the question moot. ADR 0001 needs an amendment. Decision point 4 records this.
- ADR 0001 was revised in place on 2026-10-18 (as on 2026-09-02, because nothing was provisioned): `min_replicas = 1`, the Log Analytics workspace kept with a rule that logs hold no personal data, scale to zero kept as alternative E, and two logging options recorded as alternatives F and G. This closes the ADR amendment named in decision points 4 and 13.

## Follow-up Research [2026-10-18T19:18:45+02:00]

- Logging: the operator now wants Log Analytics and requires that no personal data is logged. The first ADR revision of the same day (no stored logs) was replaced. Decision point 13 and section 5.2 record the workspace with no personal data, an explicit retention, and a post-deployment check that `ContainerAppHTTPLogs` is empty. Microsoft's table reference says `XForwardedFor` holds end-user client IP addresses and must be treated as personally identifiable information.

## Follow-up Research [2026-10-18T19:59:47+02:00]

Triggered by the operator's request to research the four remaining gaps. Four research agents ran in parallel. One returned no output and was cancelled, so I read its sources directly. I checked the RFC 5545 time zone rule and the Go month-name behaviour myself. Source marks: P is a primary text, S is secondary.

**DENIC and DNSSEC algorithm 13 (resolved)**

- A DENIC news article (P, undated, content points to about 2015) states: "Mit GOST (Algorithmus 12) und ECDSA (Algorithmen 13 und 14) lässt DENIC ab sofort drei zusätzliche Algorithmen bei den für DNSSEC-Domains übergebenen Schlüsseln zu." It names "ECDSA auf Kurve P-256 mit SHA-256 (13)". DENIC itself keeps RSA for the `.de` zone.
- Microsoft Learn (P, ms.date 2025-01-31) shows the Azure DS record as algorithm 13 with digest type 2, to be given to the registrar. The IANA registry (P) marks algorithm 13 as RECOMMENDED for signing and validation.
- The INWX knowledge base (P) shows generic algorithm and digest-type fields for external name servers and names no restriction. It does not name algorithm 13.
- Result: DNSSEC through Azure DNS is not blocked by the registry. Whether to use it, and how (AzAPI or a manual step), stays decision point 12. Gap: no current dated DENIC list.

**iCalendar and German dates (decision points 7, 8, 16)**

- RFC 5545 (P): a VCALENDAR needs PRODID and VERSION. A VEVENT needs UID and DTSTAMP, and DTSTART unless a METHOD is used. DTEND is exclusive and excludes DURATION. An all-day event uses `DTSTART;VALUE=DATE` and a DTEND one day after the last day. Lines end in CRLF and fold at 75 octets. TEXT escapes backslash, comma, and semicolon, and writes a newline as `\n`.
- Time zones (P, §3.2.19, read directly): "An individual VTIMEZONE calendar component MUST be specified for each unique TZID parameter value specified in the iCalendar object." Local times in `Europe/Berlin` therefore need a VTIMEZONE block. UTC times and all-day dates need none.
- RFC 7986 (P) adds NAME, REFRESH-INTERVAL, and SOURCE, and recommends a UUID for UID. `X-WR-CALNAME` is a common non-standard name property (S). The media type is `text/calendar` with `charset=utf-8`.
- Libraries (P, repository metadata): `arran4/golang-ical` v0.3.7 (2026-09-30), Apache-2.0, depends on go-cmp and testify. `emersion/go-ical`, MIT, has no tagged release, last push 2025-06-09, depends on rrule-go. Neither derives VTIMEZONE rules from Go time zone data. `go.mod` holds only testify and yaml today. A hand-written writer with the standard library adds no dependency.
- `time/tzdata` (P) embeds about 450 KB of zone data, so `time.LoadLocation` works in an image without `/usr/share/zoneinfo`.
- German dates: `time.Month.String` "returns the English name of the month" (`go doc`, P). Month and weekday names need a hand-written table or a library. `x/text/language` matches language tags and is not a name table. The `<time datetime>` element and the `lang` attribute are the right HTML (W3C, WHATWG, P). DIN 5008 and Duden date rules were not verified.
- Month grid (W3C APG, P): `grid` is an interactive widget whose author must code focus movement. For a server-rendered month without JavaScript, a native `<table>` with `<caption>` fits.
- Gap: vendor documentation on URL subscription and refresh for Apple, Google, and Outlook calendars was not read.

**Web baseline (decision points 3, 9, 17, 19)**

- Container Apps ingress (P): HTTP on port 80 redirects to HTTPS by default. The ARM property is `allowInsecure` (default false). In azurerm it is `allow_insecure_connections` in the `ingress` block of `azurerm_container_app` (provider main branch docs, current release 5.10.0, which satisfies `~> 5.0`). The ingress sets `X-Forwarded-Proto` and `X-Forwarded-For`. No Learn page says the ingress adds HSTS, so the app sends it (an absence of mention, not a quoted statement).
- Minimal headers (OWASP cheat sheet, S, fetched; MDN, P): `Strict-Transport-Security`, `Content-Security-Policy: default-src 'self'; frame-ancestors 'none'`, `X-Content-Type-Options: nosniff`, `Referrer-Policy`, and `Permissions-Policy`. HSTS `preload` is hard to reverse. RFC 6797 was not re-read.
- Apex versus www (P): an apex name needs an A record and a subdomain needs a CNAME, and each can have its own managed certificate. The ingress has no host redirect (rule-based routing is path-based only), so a redirect between the two names is code in the Go handler.
- `security.txt` (RFC 9116, P): `Contact` and `Expires` are required, and the file lives at `/.well-known/security.txt`. It publishes a contact address, so it is a policy choice.
- Probes (P): Container Apps adds default TCP startup, liveness, and readiness probes when ingress is on. A health endpoint is optional. `robots.txt`, the 404 page, and `favicon.ico` are general practice and I found no authoritative source to cite.
- Go server (Go source docs, P): `cmd/sudhaus-engen/main.go:42-45` sets only `ReadHeaderTimeout` (5 seconds). `ReadTimeout`, `WriteTimeout`, `IdleTimeout`, and `MaxHeaderBytes` are unset, and `IdleTimeout` falls back to `ReadTimeout`, so idle connections have no timeout. `http.MaxBytesReader` is unused, which does not matter until a handler reads a body.

**Datenschutzerklärung and operator duties (section 5.8, decision point 18)**

- A public hobby site is inside the DSGVO (Lindqvist and Ryneš). A single operator needs no data protection officer (§ 38 BDSG, Art. 37). The Art. 30(5) exemption is likely lost because the processing is not occasional, so a short internal record is the cautious choice.
- When Art. 6(1)(f) is the basis, Art. 21(4) needs a separate, visibly set apart paragraph on the right to object.
- The DSK Orientierungshilfe (Version 1.2, November 2024) covers § 25 TDDDG and banners. It does not discuss server access data as a legal-basis case, and I found no sentence that a banner-free site needs no banner.
- Section 5.8 maps each Art. 13 item to this site. LfDI Baden-Württemberg offers the "DS-GVO.clever" generator. I did not read its output.
- Source note: the agent assigned to this topic was cancelled with no result. The Art. 30 guidance on the LfDI Baden-Württemberg site returned a 404 page, so I used the DSK Kurzpapier Nr. 1 instead.
