---
date: 2026-10-18T21:09:17+02:00
researcher: "GitHub Copilot"
agent_llm: "claude-sonnet-5.5"
git_commit: c4790005aa14abfab5866d68456b88b9ba2e6327
branch: main
repository: sudhaus-engen
topic: "Issue tree for rolling out the sudhaus-engen.de site"
tags: [plan, rollout, issues, batch, tasks, how-we-work]
status: complete
research_document: ".github/ace-fca/research/0001-site-rollout-requirements.md"
last_updated: 2026-11-01
last_updated_by: "GitHub Copilot"
---

# Plan: Issue tree for the site rollout

## Original Prompt

> @.github/prompts/planning.prompt.md .github/ace-fca/research/0001-site-rollout-requirements.md  We need a plan to create tasks, batches, and maybe an epic.

---

## Overview

This plan turns research 0001 into a GitHub issue tree: one batch, "Launch sudhaus-engen.de", with nine task sub-issues and eleven dependency links. Running this plan creates issues and writes no application code. Each task is later worked as one ACE-FCA cycle and one PR, as `docs/how-we-work.md` defines.

## Settled decisions

All decisions below were made with the operator on 2026-10-18. The research document holds the reasoning and the rejected alternatives.

- **Structure** (research point 11): one batch, no epic, nine tasks. A batch title needs a prefix only when an epic exists, so the batch has none.
- **Publication gate**: no image is promoted to production before the Impressum and the Datenschutzerklärung are merged. The generated Azure URL is public as soon as the real image runs.
- **Hostname** (point 3): apex `sudhaus-engen.de` only. No `www` name and no redirect.
- **Impressum** (points 1, 2, 14): basis § 18 Abs. 1 MStV. It shows name, postal address, and email address.
- **DNS** (point 12): Azure DNS zone, delegated from INWX. DNSSEC is not part of this plan.
- **Hosting** (points 4, 13): `min_replicas = 1`, Log Analytics workspace without `ContainerAppHTTPLogs`, retention of 30 days. The operator confirmed the 30-day value. The Datenschutzerklärung task states it and the Terraform task applies it.
- **Calendar** (points 7, 8, 16): a list page fed by an embedded data file. The ADR in the brew-day task sets the file format and the time representation.
- **Fonts and assets** (points 5, 15): one hand-written stylesheet and self-hosted SIL OFL fonts, embedded in the binary.
- **Delivery** (points 9, 19): scripts under `script/`, confirmed with the `az` CLI. No health endpoint.
- **Security and records** (points 17, 18): response headers and server timeouts are one task. A short records-of-processing file is part of the Datenschutzerklärung task.

## Starting state

- `gh issue list --state all` returns no issues for `jmoody/sudhaus-engen`.
- The site has one route, `GET /{$}`, and one template (`internal/web/web.go:15-16,36,47-51`, `internal/web/templates/index.html`). It has no layout, stylesheet, static route, or footer.
- `.dockerignore` allows `internal`, so assets placed under `internal/web/` reach the Docker build without a change.
- `cmd/sudhaus-engen/main.go:43-45` sets only `ReadHeaderTimeout`.
- `terraform/envs/prod/main.tf` declares no resources.
- `script/register-providers` registers five providers. `Microsoft.ManagedIdentity` is missing.
- `origin/main` does not hold the local commit `c479000` ("dockerized service", 24 files). That commit holds research 0001, `docs/how-we-work.md`, `docs/deployment-with-scripts.md`, and the Dockerfile, `internal/web` code, and Makefile changes that T1, T4, and T9 edit. `main` has no branch protection or rulesets. The plan and retro are untracked.

## Issue tree

| ID | Issue                                             | Title                                                         | Blocked by |
| -- | ------------------------------------------------- | ------------------------------------------------------------- | ---------- |
| T1 | https://github.com/jmoody/sudhaus-engen/issues/2  | Site shell, stylesheet, and self-hosted fonts                 | none       |
| T2 | https://github.com/jmoody/sudhaus-engen/issues/3  | Impressum page                                                | T1         |
| T3 | https://github.com/jmoody/sudhaus-engen/issues/4  | Datenschutzerklärung, records of processing, and logging rule | T1         |
| T4 | https://github.com/jmoody/sudhaus-engen/issues/5  | Brew-day list with event data and ADR                         | T1         |
| T5 | https://github.com/jmoody/sudhaus-engen/issues/6  | Terraform core for the Container App                          | none       |
| T6 | https://github.com/jmoody/sudhaus-engen/issues/7  | Delivery scripts: build, push, and promote                    | T2, T3, T5 |
| T7 | https://github.com/jmoody/sudhaus-engen/issues/8  | Azure DNS zone and INWX delegation                            | T5         |
| T8 | https://github.com/jmoody/sudhaus-engen/issues/9  | Apex records, custom domain, and managed certificate          | T4, T6, T7 |
| T9 | https://github.com/jmoody/sudhaus-engen/issues/10 | Security headers and server timeouts                          | T1         |

The batch "Launch sudhaus-engen.de" is https://github.com/jmoody/sudhaus-engen/issues/1.

Suggested order for one engineer: T1, T2, T3, T9, T5, T6, T7, T4, T8. The order is not binding. The dependency links are.

## Rules for task content

- **Boundary test.** If the next task never happens, this task's PR is still correct, complete, and leaves no code, link, or output that only a later task uses. A dependency is allowed. A partial implementation is not.
- **Observable outcome.** Each task has a "Done when" list of checks that a person can run. Tasks that change code also pass `make review`.
- **Writing.** Issue text uses ASD-STE100 Simplified Technical English: short sentences, active voice, one idea per sentence. References to issues and pull requests use full URLs.
- **Public repository.** No issue contains the operator's postal address or email address. The operator gives these values to the task that publishes them.
- **Labels.** No new labels. Tasks get `enhancement`. The batch gets none.

## What we are NOT doing

- No epic and no title prefix.
- No `.ics` feed, month grid, DNSSEC, `security.txt`, health endpoint, `www` name, CAA record, or image-retention policy.
- No CI/CD pipeline. `docs/deployment-with-scripts.md` keeps its script-based model.
- No application code, Terraform, or scripts in this plan. The tasks own all of it.
- No lawyer review or check of Microsoft's own retention period. The operator accepted these as unverified.

## Implementation phases

### Phase 1: Prepare the issue content

#### Implementation steps

1. Push the local commit `c479000` to `origin/main`, so the links in the issue bodies resolve and the task code exists on `main`. Link the documents as `https://github.com/jmoody/sudhaus-engen/blob/main/<path>`.
2. Run `gh auth status` and confirm access to this repository.
3. Write ten files in `./tmp/issues/`: `batch.md` and `t1.md` to `t9.md`. Use the text in "Issue content" below. Turn each bold label into a `##` heading.
4. Check every draft against the boundary test and the writing rules above.

#### Success criteria

- [x] `origin/main` holds commit `c479000`, including the three documents.
- [x] Ten drafts exist. Each task draft has Goal, Scope, Done when, and Blocked by.
- [x] No draft contains the operator's postal address or email address.

### Phase 2: Create the issues and link the sub-issues

#### Implementation steps

1. Create the batch with `gh issue create --title "Launch sudhaus-engen.de" --body-file tmp/issues/batch.md`.
2. Create each task with `gh issue create --title "<title>" --body-file tmp/issues/tN.md --label enhancement --assignee @me`. Use the exact titles from the tree table.
3. Record every issue number and its database id (`gh api repos/jmoody/sudhaus-engen/issues/<n> --jq .id`).
4. Link each task to the batch: `gh api -X POST repos/jmoody/sudhaus-engen/issues/<batch>/sub_issues -F sub_issue_id=<task_db_id>`.

#### Success criteria

- [x] `gh api repos/jmoody/sudhaus-engen/issues/<batch>/sub_issues --jq length` prints `9`.
- [x] The title of each sub-issue matches the tree table.

### Phase 3: Add the dependencies and verify

#### Implementation steps

1. For each row of the tree table, add one link per blocker: `gh api -X POST repos/jmoody/sudhaus-engen/issues/<blocked>/dependencies/blocked_by -F issue_id=<blocker_db_id>`. Use the blocker's database id, not its number.
2. For each task, run `gh api repos/jmoody/sudhaus-engen/issues/<n>/dependencies/blocked_by --jq 'map(.number)'` and compare the result with the table.
3. Add an "Issue" column with the real numbers to the tree table in this plan.
4. Delete the files that this plan created in `./tmp/issues/`.
5. Open a draft pull request with the plan and the finalized retro. Request Copilot Code Review and iterate until a review returns no actionable comments.

#### Success criteria

- [x] Eleven dependency links exist and match the tree table.
- [x] T6 lists T2, T3, and T5 as its blockers.
- [x] `gh issue list --state open` shows ten issues: the batch and nine tasks.
- [ ] The retro is finalized and the plan status is `complete`.
- [ ] The draft pull request has a clean Copilot Code Review.

Rollback: close the ten issues as "not planned". The plan changes nothing else.

## Issue content

### Batch: Launch sudhaus-engen.de

**Goal**: Publish the German brewing-calendar site at https://sudhaus-engen.de on Azure Container Apps, with the legal pages and a brew-day list.

**Scope**: The nine task sub-issues of this batch. This batch opens no pull request.

**Done when** all of these are true:

- All nine tasks are closed.
- https://sudhaus-engen.de serves the site over HTTPS with the Azure-managed certificate.
- Every page links to the Impressum and the Datenschutzerklärung.
- The Datenschutzerklärung states the same log retention as the Log Analytics workspace: 30 days.
- A query on the Log Analytics workspace shows no rows in `ContainerAppHTTPLogs`.
- The site sets no cookie and sends no request to another host. Check this in the browser network tab.

**Order rule**: Do not promote an image to production before the Impressum and the Datenschutzerklärung are merged.

**Out of scope**: `.ics` feed, month grid, DNSSEC, `security.txt`, health endpoint, `www` name.

**References**: research 0001, `docs/how-we-work.md`, `docs/deployment-with-scripts.md`, and ADR 0001, all as full `blob/main` URLs.

### T1: Site shell, stylesheet, and self-hosted fonts

**Goal**: All pages use one German layout and one stylesheet.

**Scope**:

- Split `internal/web/templates/index.html` into a base layout (header, main, footer) and an index page that uses it. Set `lang="de"`.
- Parse each page template together with the layout into one page set. Add one `render` helper in `internal/web/web.go` that executes a page into a buffer, logs a failure, returns a 500, sets the content type, and writes the result. `handleIndex` uses it. Later pages add a route and a short handler, and no new `Server` field.
- Add embedded static files under `internal/web/static/` and serve them at `/static/`. A directory under `internal/` needs no change to `.dockerignore`.
- Add one hand-written stylesheet. It works on a small screen. It needs no build step and no new dependency.
- Add the operator's chosen Inconsolata Nerd Font Mono regular and bold files (SIL OFL). Serve them from the same host and include the font license.
- Use the font site-wide, with a warm light/dark palette and copper accent. Keep the header and footer simple, showing the site name with no footer links.
- Replace the chi paragraph in `.github/instructions/go.instructions.md` ("HTTP handler design") with the `net/http` `ServeMux` pattern that `Handler()` uses: method-and-path patterns such as `GET /{$}`, and no router dependency. The repository holds no chi code and no `internal/api/rest/routes.go`.
- Use no inline `<style>`, no `style` attribute, and no inline script in any template.
- Do not add footer links. The Impressum task and the Datenschutzerklärung task add their own links.
- The index page keeps its placeholder text. The brew-day list task replaces it.

**Done when**:

- `make review` passes.
- `GET /` returns a page that uses the shared layout and links the stylesheet.
- `GET /static/<stylesheet>` returns 200 with `text/css`. An unknown static path returns 404.
- The browser network tab shows no request to another host.
- `make docker-run` shows the styled page.
- `.github/instructions/go.instructions.md` describes `ServeMux` routing and does not mention chi.

**Blocked by**: none.

### T2: Impressum page

**Goal**: The site publishes an Impressum that meets § 18 Abs. 1 MStV.

**Scope**:

- Add `GET /impressum`. Its template uses the shared layout and its handler uses the `render` helper.
- Show the operator's first name, last name, postal address, and email address. The operator gives these values when the task starts. Do not write them in this issue.
- Add an "Impressum" link to the shared footer, so that every page links to it.
- Add tests for the route and the footer link.

**Done when**:

- `make review` passes.
- `GET /impressum` returns 200 with the name, postal address, and email address.
- `GET /` and `GET /impressum` both contain the "Impressum" footer link.

**Blocked by**: T1.

**Notes**: The email address is the operator's choice. No lawyer reviewed this reading (research section 5.1).

### T3: Datenschutzerklärung, records of processing, and logging rule

**Goal**: The site publishes a Datenschutzerklärung that matches how the site works.

**Scope**:

- Add `GET /datenschutz` and a "Datenschutzerklärung" footer link. The template uses the shared layout and the handler uses the `render` helper.
- Write the text in German. Cover each Art. 13 DSGVO item in the table in research section 5.8: controller, no data protection officer, purpose and legal basis (Art. 6(1)(f)), recipients, third-country transfer, retention, rights, complaint, no duty to provide data, no automated decision.
- Name Microsoft as host and as an independent controller for its own business operations. Refer to the Microsoft DPA.
- State that the site sets no cookie, uses no tracking tool, and loads no third-party resource.
- State that the logs hold no personal data and that the log retention is 30 days. The Terraform core task sets the same value.
- Add a separate paragraph on the right to object (Art. 21(4) DSGVO).
- Name the supervisory authority: LfDI Baden-Württemberg.
- Add `docs/records-of-processing.md`. It lists categories and processors only, and no personal data.
- Add the no-personal-data logging rule to `.github/instructions/go.instructions.md`. ADR 0001 lists this as follow-up work.

**Done when**:

- `make review` passes.
- `GET /datenschutz` returns 200. Every page links to it.
- The text covers each Art. 13 item. The PR lists where.
- The right to object has its own paragraph.
- `docs/records-of-processing.md` exists and agrees with the text.
- `.github/instructions/go.instructions.md` states the logging rule.

**Blocked by**: T1.

**Notes**: No lawyer reviewed this text. Microsoft's own retention period is not known and the operator accepted that (research section 5.2).

### T4: Brew-day list with event data and ADR

**Goal**: The home page lists brew days from an embedded data file, with German dates.

**Scope**:

- Write an ADR with the `adr-author` skill for the event format: the data file format and the time representation (all-day dates or timed events). ADR 0001 asks for it. Use only packages that `go.mod` already holds. Add no new dependency.
- Add the embedded data file, a loader that validates it, and tests.
- Replace the placeholder on `GET /{$}` with a list of brew days in date order, rendered with the `render` helper. Use German month and weekday names from a name table, because `time.Month.String` returns English names. Use the `<time datetime>` element.
- Add the German intro text and the first brew-day entries. The operator supplies them.
- Use no JavaScript.

**Done when**:

- `make review` passes.
- The ADR is merged with status Accepted.
- `GET /` lists every entry of the data file in date order, with German dates.
- A test shows that an invalid data file is rejected.
- The text "Hello world" is gone.

**Blocked by**: T1.

**Out of scope**: `.ics` feed and month grid.

### T5: Terraform core for the Container App

**Goal**: `make apply` creates the Azure resources that run the site. A placeholder image runs on them.

**Scope** (in `terraform/envs/prod`, following `.github/instructions/terraform.instructions.md`):

- Add `Microsoft.ManagedIdentity` to `script/register-providers`: the `REQUIRED_PROVIDERS` array, the header comment, and the `usage()` text. Add it to the provider table in `terraform/README.md` and change the prose counts there to six providers.
- Create a resource group, a Log Analytics workspace with 30-day retention, a Container Registry, a user-assigned identity, an `AcrPull` role for the identity, an `AcrPush` role for the operator, a Container Apps environment with `logs_destination = "log-analytics"`, and a Container App.
- Set the Container App to single-revision mode, `min_replicas = 1`, external ingress with `target_port = 8000`, and `ignore_changes` on the image.
- Create no diagnostic setting for `ContainerAppHTTPLogs`.
- Add outputs for the resource group name, the registry login server, the app name, and the app default host name.
- Delete the "No workload resources yet" comment at the end of `terraform/envs/prod/main.tf`. Rewrite the sentence in `terraform/README.md` that says the prod root provisions no resources, so that it states only what the root holds after this task. Write no history.

**Edge case**: The site listens on `PORT`, default 8000, so the ingress `target_port` is fixed at 8000. The placeholder image must answer on 8000. Pick an image that honors a port setting, or set one, and record the choice in the PR. If no image works, stop and report. Do not change the target port, because the promote script in the next task does not touch Terraform.

**Done when**:

- `make review` passes.
- The provider list in the `register-providers` array, header comment, and `usage()` text, and the table and counts in `terraform/README.md`, all name the same six providers.
- `make plan` shows only the expected resources. Every taggable resource has the `service` and `environment` tags.
- After `make apply`, a second `make plan` shows no changes.
- The placeholder app answers over HTTPS at its default host name.
- `az containerapp show` reports a minimum of 1 replica.
- No diagnostic setting sends `ContainerAppHTTPLogs` to the workspace.

**Blocked by**: none.

### T6: Delivery scripts: build, push, and promote

**Goal**: One command builds and pushes an image tagged with the git SHA. One command promotes it.

**Scope** (from `docs/deployment-with-scripts.md`):

- Add `script/image-push`. It refuses a dirty working tree and an unpushed commit. It runs `docker buildx build --platform linux/amd64`, tags the image with the git SHA (never `latest`), runs `az acr login`, and pushes.
- Add `script/promote <sha>`. It runs `az containerapp update --image <registry>/<image>:<sha>`, waits for the new revision, and exits with an error if the revision is not healthy.
- Add the make targets `image-push` and `promote SHA=<sha>`.
- Follow `.github/instructions/bash.instructions.md`.
- Update `docs/deployment-with-scripts.md`. Set the status to implemented and remove the open points that this task settles. Image retention stays open.
- Run both scripts against production. This is the first public release of the site image.

**Done when**:

- `make review` passes, including shellcheck.
- `az acr repository show-tags` lists the SHA tag.
- `promote` exits 0 and the app serves the new image at its default host name.
- Promoting a tag that does not exist exits with an error. The running revision stays in place.
- Promoting an earlier SHA works, which is the rollback path.
- A few minutes after some requests, a Log Analytics query shows no rows in `ContainerAppHTTPLogs`. ADR 0001, decision step 7, requires this check.

**Blocked by**: T2, T3, T5.

**Notes**: This task carries the publication gate. Do not run `promote` before the Impressum and the Datenschutzerklärung are merged.

### T7: Azure DNS zone and INWX delegation

**Goal**: Azure DNS answers for `sudhaus-engen.de`.

**Scope**:

- Add an `azurerm_dns_zone` for `sudhaus-engen.de` to the prod root, with the required tags and an output for its name servers.
- Create the zone before any change at INWX. DENIC checks the name servers when they change, and the change fails if the zone does not exist yet.
- The operator enters at least two Azure name servers at INWX under "Externe Nameserver" and waits for the change to apply. This can take 3 to 48 hours.
- Document the steps in `terraform/README.md`.
- Add no records. The records task adds them.

**Done when**:

- `make review` passes.
- The zone exists after `make apply`, and a second `make plan` shows no changes.
- `dig +short NS sudhaus-engen.de` from a public resolver returns the Azure name servers.
- `terraform/README.md` documents the delegation steps.

**Blocked by**: T5.

### T8: Apex records, custom domain, and managed certificate

**Goal**: https://sudhaus-engen.de serves the site with an Azure-managed certificate.

**Scope** (in the prod root):

- Add an A record at the apex that points to the Container Apps environment static IP address. Add the `asuid` TXT record with the app's verification ID. Create both before the custom domain.
- Add the custom domain for `sudhaus-engen.de` and a managed certificate with HTTP validation. Choose the resource combination that works with the pinned `~> 5.0` provider. Research section 4.2 lists the candidates. Explain the choice in a comment.
- Add no CAA record, no `www` name, and no redirect in the application.
- Add the custom domain and certificate to `terraform/README.md`, in the present tense.

**Done when**:

- `make review` passes.
- https://sudhaus-engen.de returns 200 with a valid certificate.
- `http://sudhaus-engen.de` redirects to HTTPS.
- A `make plan` after `make apply` shows no changes.
- All "Done when" items of the batch that describe the live site are true. Task closure is not one of them.

**Blocked by**: T4, T6, T7.

**Notes**: The app must run while the certificate is issued and renewed. T5 sets `min_replicas = 1` for this reason.

### T9: Security headers and server timeouts

**Goal**: Every response carries the security headers, and the server closes slow connections.

**Scope**:

- Add middleware in `internal/web`. It sets `Strict-Transport-Security` (without `preload`), `Content-Security-Policy: default-src 'self'; frame-ancestors 'none'`, `X-Content-Type-Options: nosniff`, `Referrer-Policy`, and `Permissions-Policy` on every response, including error responses and static files.
- Add `readTimeout`, `writeTimeout`, and `idleTimeout` constants to the existing const block in `cmd/sudhaus-engen/main.go`, beside `readHeaderTimeout`, and set them in the `http.Server` literal. State each value and one sentence of reasoning in the PR description.
- Add tests for the headers on `/`, on a static file, and on a 404.

**Done when**:

- `make review` passes.
- The tests pass.
- The pages load in a browser with no content security policy violation in the console.
- `curl -I` on a running server shows the headers.

**Blocked by**: T1.

## Scope validation

- [x] Every task has a justification in research 0001.
- [x] No task is driven by a hypothetical future need.
- [x] No task builds a framework or a stub for another task.
- [x] Each task delivers a result that stands alone.
- [x] Complexity matches the nine-task, one-batch decision.

## References

- Research: `.github/ace-fca/research/0001-site-rollout-requirements.md`
- Work levels and rules: `docs/how-we-work.md`
- Delivery model: `docs/deployment-with-scripts.md`
- Hosting decision: `docs/adrs/0001-host-on-azure-container-apps-in-sweden-central-with-terraform-and-docker.md`
- Terraform rules: `.github/instructions/terraform.instructions.md`
- Retrospective: `.github/ace-fca/retros/0001-site-rollout.md`
