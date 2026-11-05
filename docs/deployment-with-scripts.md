---
title: Deployment with scripts
description: Initial deployment model for sudhaus-engen, where the operator builds, pushes, and promotes container images from a local machine.
---

# Deployment with scripts

Status: implemented. This document records the deployment model chosen on 2026-10-18 and the scripts that now carry it out. It follows [ADR 0001](adrs/0001-host-on-azure-container-apps-in-sweden-central-with-terraform-and-docker.md), which puts the service on Azure Container Apps in Sweden Central.

## Model

The operator builds the container image on a local machine, pushes it to Azure Container Registry, and promotes it to the running app from the same machine. There is no CI/CD pipeline. A pipeline can replace the scripts later without changing the infrastructure.

Promotion replaces the running revision immediately. The Container App runs in single-revision mode, so there is no traffic shifting and no staged revision. The platform keeps the old revision until the new one is healthy.

## Split between Terraform and scripts

Terraform owns the infrastructure. Scripts under `script/` own the delivery of images. The repo convention is a bash script that loads `.env` and runs the tool, as described in `.github/instructions/bash.instructions.md`.

| Concern                       | Owner                                     |
| ----------------------------- | ----------------------------------------- |
| Resource group                | Terraform                                 |
| Container registry            | Terraform                                 |
| Log Analytics workspace       | Terraform                                 |
| Container Apps environment    | Terraform                                 |
| Container app                 | Terraform, with `ignore_changes` on image |
| User-assigned identity        | Terraform                                 |
| `AcrPull` role assignment     | Terraform                                 |
| DNS zone and domain binding   | Terraform, in a later change              |
| Build and push of the image   | Script                                    |
| Promotion of a new image      | Script                                    |

Terraform creates the container app with a placeholder image. The `ignore_changes` setting on the image keeps `terraform apply` from reverting an image that a script promoted.

## Steps

1. The operator signs in with `make az-login`.
2. `make image-push` builds the image with `docker buildx build --platform linux/amd64`. Container Apps cannot run arm64 images, so this flag is required on an Apple Silicon Mac.
3. The script tags the image with the git commit SHA of `HEAD`. It does not use `latest`, so each promotion names an exact build and a rollback names an earlier SHA.
4. The script runs `az acr login` and pushes.
5. `make promote SHA=<sha>` runs `az containerapp update --image <registry>/<image>:<git-sha>`. This creates a new revision that replaces the running one.

The app pulls from the registry with its user-assigned identity and the `AcrPull` role. The operator pushes with their own Azure CLI sign-in, which needs `AcrPush` on the registry.

## Scripts

Both scripts read the registry, app, and resource group from the Terraform outputs of `terraform/envs/prod`, so no name is written down twice. They share `script/lib/azure-session.bash` with `script/az-login` and `script/terraform`, which resolves the subscription id and points the Azure CLI at the repo-local `.azure/` session.

| Command                  | Script              | What it does                                                               |
| ------------------------ | ------------------- | -------------------------------------------------------------------------- |
| `make image-push`        | `script/image-push` | Builds for `linux/amd64`, tags with the `HEAD` SHA, and pushes it          |
| `make promote SHA=<sha>` | `script/promote`    | Points the app at that tag and waits for the new revision to report healthy |

`image-push` refuses to build when the working tree has uncommitted changes or when `HEAD` is not on any branch at `origin`. Together these guarantee that every tag in the registry names a commit anyone can check out. SHA tags are also write-once: if the tag already exists, `image-push` reports it and leaves the published image alone rather than rebuilding over it. The Dockerfile builds on a mutable `ubuntu` base, so an overwrite would quietly change what an already-deployed SHA means and break rolling back to it.

`promote` checks that the tag exists in the registry before it touches the app, so promoting an unknown SHA leaves the running revision in place. It accepts any revision git understands and resolves it to a full SHA, so a short SHA from `git log --oneline` works. After the update it polls the new revision until `provisioningState` is `Provisioned`, `runningState` is `Running`, and `healthState` is `Healthy`, and exits non-zero if that does not happen within five minutes.

## Rollback

Rollback is a promotion of an earlier git SHA: `make promote SHA=<earlier-sha>`. Every pushed SHA stays in the registry until it is deleted, and its tag is never rewritten, so an earlier SHA always restores the exact image that was deployed.

## Open points

- Retention of old images in the registry.
