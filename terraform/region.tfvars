# Region pin for every engen-brews Azure workload stack, shared by all roots.
#
# West Europe is the chosen region, matching ADR-0001. Pinning to a single EU
# region is a compliance decision: it keeps visitor data, event content, and
# backups in one EU geography and avoids international-transfer complexity.
#
# This value is non-secret per-environment data, so it is committed (see
# terraform/.gitignore, which tracks *.tfvars on purpose). Each root declares
# variable "location" with no default and consumes this file explicitly at
# apply time via -var-file=../../region.tfvars, so a forgotten region fails
# loudly rather than silently falling back to a provider default.

location = "westeurope"
