# The region is pinned to West Europe for every sudhaus-engen workload resource.
# It is declared with no default so a plan or apply that forgets
# -var-file=../../region.tfvars fails loudly rather than silently falling back
# to a provider default. See terraform/README.md, "Region".
variable "location" {
  description = "Azure region for every resource in this root, supplied via -var-file=../../region.tfvars."
  type        = string
}

# The subscription id is an input, never a literal in a *.tf or *.tfvars file,
# so Terraform stays subscription-portable. It has no default so a missing
# value fails loudly instead of silently falling back to the Azure CLI's active
# subscription. script/terraform supplies it as TF_VAR_subscription_id.
variable "subscription_id" {
  description = "Azure subscription id for this root, supplied via TF_VAR_subscription_id or -var, never a literal in configuration."
  type        = string
}
