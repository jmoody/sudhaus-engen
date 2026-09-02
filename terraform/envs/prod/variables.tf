# The region is pinned to West Europe for every engen-brews workload resource.
# It is declared with no default so a plan or apply that forgets
# -var-file=../../region.tfvars fails loudly rather than silently falling back
# to a provider default. See terraform/README.md, "Region".
variable "location" {
  description = "Azure region for every resource in this root, supplied via -var-file=../../region.tfvars."
  type        = string
}

# The subscription id is an input, never committed: this repository is public
# and Terraform must be subscription-portable. It has no default so a missing
# value fails loudly instead of silently falling back to the Azure CLI's active
# subscription. Supply it out-of-band, e.g. export TF_VAR_subscription_id=...
variable "subscription_id" {
  description = "Azure subscription id for this root, supplied via TF_VAR_subscription_id or -var, never committed."
  type        = string
}
