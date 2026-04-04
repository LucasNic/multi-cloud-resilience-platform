###############################################################################
# Terragrunt Root Configuration
#
# State backend: GCS (Google Cloud Storage)
# Provider generation: Azure, GCP, and shared based on path
#
# Path convention: live/<cloud>/<region>/<environment>/<module>
# Examples:
#   live/azure/eastus/dev/aks
#   live/gcp/us-central1/dev/gke
#   live/shared/global/dev/cockroachdb
#   live/shared/global/dev/cloudflare-dns
###############################################################################

locals {
  path_components = split("/", path_relative_to_include())
  cloud           = local.path_components[0]
  region          = local.path_components[1]
  environment     = local.path_components[2]
  module_name     = local.path_components[3]
  project_prefix  = "multicloud"
  state_key       = "${local.cloud}/${local.region}/${local.environment}/${local.module_name}/terraform.tfstate"
}

# --- Remote State: GCS ---

remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = "multicloud-tfstate-492119"
    prefix = local.state_key
  }
}

# --- Provider Generation based on cloud path ---

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-PROVIDER
    %{if local.cloud == "azure"}
    provider "azurerm" {
      features {}
    }
    provider "azuread" {}
    %{endif}

    %{if local.cloud == "gcp"}
    provider "google" {
      project = "${get_env("GCP_PROJECT_ID")}"
      region  = "${local.region}"
    }
    %{endif}

    %{if local.cloud == "shared"}
    # Shared modules may use cloudflare or cockroach providers
    # Individual module versions.tf declares required_providers
    %{endif}
  PROVIDER
}

# --- Common inputs passed to all modules ---

inputs = {
  project_prefix = local.project_prefix
  environment    = local.environment
  region         = local.region
}

terraform {
  extra_arguments "retry_lock" {
    commands  = get_terraform_commands_that_need_locking()
    arguments = ["-lock-timeout=5m"]
  }
}
