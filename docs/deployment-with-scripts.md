---
title: Deployment with scripts
description: Initial deployment model for sudhaus-engen, where the operator builds, pushes, and promotes container images from a local machine.
---

# Deployment with scripts

Status: idea, not yet planned or implemented. This document records the deployment model chosen on 2026-10-18 so that a later plan can build on it. It follows [ADR 0001](adrs/0001-host-on-azure-container-apps-in-west-europe-with-terraform-and-docker.md), which puts the service on Azure Container Apps in West Europe.

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
2. A build-and-push script builds the image with `docker buildx build --platform linux/amd64`. Container Apps cannot run arm64 images, so this flag is required on an Apple Silicon Mac.
3. The script tags the image with the git commit SHA. It does not use `latest`, so each promotion names an exact build and a rollback names an earlier SHA.
4. The script runs `az acr login` and pushes the image.
5. A promote script runs `az containerapp update --image <registry>/<image>:<git-sha>`. This creates a new revision that replaces the running one.

The app pulls from the registry with its user-assigned identity and the `AcrPull` role. The operator pushes with their own Azure CLI sign-in, which needs `AcrPush` on the registry.

## Rollback

Rollback is a promotion of an earlier git SHA. Every pushed SHA stays in the registry until it is deleted.

## Open points

- The names and arguments of the build-and-push and promote scripts.
- Whether `make` targets wrap the scripts, as they do for `plan` and `apply`.
- A check that the working tree is clean and the SHA is pushed before a build, so every image maps to a commit.
- How the operator confirms a promotion succeeded, for example a health endpoint on the service.
- `Microsoft.ManagedIdentity` must be added to `script/register-providers`.
- Retention of old images in the registry.
