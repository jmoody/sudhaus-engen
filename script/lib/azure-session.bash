#!/usr/bin/env bash
# script/lib/azure-session.bash is sourced by every script that talks to Azure.
# It resolves the subscription id the same way everywhere (the environment
# overrides .env, which overrides defaults.subscription in the tracked
# .azure/config), points the Azure CLI at the repo-local .azure/ session that
# script/az-login establishes, and reads values out of the prod Terraform
# state. It is sourced, never executed.

readonly TF_ENV_DIR="terraform/envs/prod"

PROJECT_DIR="$(git rev-parse --show-toplevel)"
readonly PROJECT_DIR

log_info() {
  echo "[INFO] $*" >&2
}

log_error() {
  echo "[ERROR] $*" >&2
}

require_az() {
  if ! command -v az > /dev/null 2>&1; then
    log_error "Azure CLI (az) is not installed."
    log_error "Install it from https://learn.microsoft.com/cli/azure/install-azure-cli"
    exit 1
  fi
}

require_terraform() {
  if ! command -v terraform > /dev/null 2>&1; then
    log_error "Terraform is not installed."
    log_error "Install it from https://developer.hashicorp.com/terraform/install"
    exit 1
  fi
}

load_dotenv() {
  [[ -n "${AZ_SUBSCRIPTION_ID:-}" ]] && return 0
  [[ -f "${PROJECT_DIR}/.env" ]] || return 0

  local line value
  while IFS= read -r line || [[ -n "${line}" ]]; do
    case "${line}" in
      AZ_SUBSCRIPTION_ID=*)
        value="${line#AZ_SUBSCRIPTION_ID=}"
        value="${value#"${value%%[![:space:]]*}"}"
        case "${value}" in
          \"*)
            value="${value#\"}"
            value="${value%%\"*}"
            ;;
          \'*)
            value="${value#\'}"
            value="${value%%\'*}"
            ;;
          *)
            value="${value%%#*}"
            value="${value%"${value##*[![:space:]]}"}"
            ;;
        esac
        [[ -n "${value}" ]] && export AZ_SUBSCRIPTION_ID="${value}"
        ;;
    esac
  done < "${PROJECT_DIR}/.env"
}

load_azure_config_default() {
  [[ -n "${AZ_SUBSCRIPTION_ID:-}" ]] && return 0

  local config="${PROJECT_DIR}/.azure/config"
  [[ -f "${config}" ]] || return 0

  local line section="" value
  while IFS= read -r line || [[ -n "${line}" ]]; do
    case "${line}" in
      \[*\]) section="${line}" ;;
      subscription*=*)
        [[ "${section}" == "[defaults]" ]] || continue
        value="${line#*=}"
        value="${value//[[:space:]\"\']/}"
        [[ -n "${value}" ]] && export AZ_SUBSCRIPTION_ID="${value}"
        ;;
    esac
  done < "${config}"
}

resolve_subscription() {
  load_dotenv
  load_azure_config_default
  AZ_SUBSCRIPTION_ID="${AZ_SUBSCRIPTION_ID:?set AZ_SUBSCRIPTION_ID (e.g. in .env) or defaults.subscription in .azure/config}"
  export AZ_SUBSCRIPTION_ID
}

use_repo_azure_config() {
  export AZURE_CONFIG_DIR="${PROJECT_DIR}/.azure"
}

have_valid_session() {
  az account get-access-token \
    --subscription "${AZ_SUBSCRIPTION_ID}" \
    --only-show-errors \
    --output none > /dev/null 2>&1
}

require_session() {
  if ! have_valid_session; then
    log_error "No valid Azure session for subscription ${AZ_SUBSCRIPTION_ID}."
    log_error "Run \"make az-login\" first."
    exit 1
  fi
}

terraform_output() {
  local name="$1"
  local value

  # ARM_SUBSCRIPTION_ID pins the backend to the resolved subscription. Without
  # it the azurerm backend falls back to the Azure CLI's active subscription,
  # which AZ_SUBSCRIPTION_ID may deliberately override.
  if ! value="$(ARM_SUBSCRIPTION_ID="${AZ_SUBSCRIPTION_ID}" \
    terraform -chdir="${PROJECT_DIR}/${TF_ENV_DIR}" output -raw "${name}" 2> /dev/null)" \
    || [[ -z "${value}" ]]; then
    log_error "Could not read the Terraform output \"${name}\" from ${TF_ENV_DIR}."
    log_error "Run \"make tf-init\" and \"make apply\" first."
    return 1
  fi

  printf '%s\n' "${value}"
}
