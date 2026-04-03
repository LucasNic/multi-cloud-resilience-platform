###############################################################################
# OCI GitHub Actions IAM Setup
#
# OCI does not support OIDC federation via oci_identity_identity_provider
# for external IdPs like GitHub. Instead, we create a dedicated IAM user
# with an API key for CI/CD, scoped to the project compartment.
#
# The API key credentials (user OCID + fingerprint + private key) are stored
# as GitHub Actions secrets and used by the OCI Terraform provider in CI.
###############################################################################

# --- IAM Group for CI/CD ---

resource "oci_identity_group" "github_actions" {
  compartment_id = var.tenancy_ocid
  name           = "${var.project_prefix}-github-actions"
  description    = "GitHub Actions CI/CD group for ${var.project_prefix}"

  freeform_tags = local.common_tags
}

# --- IAM Policy: what the CI/CD group can do ---

resource "oci_identity_policy" "github_actions_terraform" {
  compartment_id = var.tenancy_ocid
  name           = "${var.project_prefix}-github-actions-terraform"
  description    = "Allow GitHub Actions to manage ${var.project_prefix} infrastructure"

  statements = [
    "Allow group ${oci_identity_group.github_actions.name} to manage all-resources in compartment id ${var.compartment_id}",
    "Allow group ${oci_identity_group.github_actions.name} to read all-resources in tenancy",
  ]

  freeform_tags = local.common_tags
}

# --- Locals ---

locals {
  common_tags = merge(
    {
      project    = var.project_prefix
      managed_by = "terraform"
      module     = "oci-oidc-github"
      purpose    = "ci-cd-federation"
    },
    var.extra_tags
  )
}

# --- Variables ---

variable "tenancy_ocid" {
  description = "OCI tenancy OCID (root compartment)"
  type        = string
}

variable "compartment_id" {
  description = "OCI compartment OCID where infrastructure is deployed"
  type        = string
}

variable "project_prefix" {
  type = string
}

variable "github_repo" {
  description = "GitHub repo in org/repo format (e.g. lucasnicoloso/multi-cloud-portfolio)"
  type        = string
}

variable "github_branch" {
  description = "Branch allowed to run apply (e.g. main)"
  type        = string
  default     = "main"
}

variable "extra_tags" {
  type    = map(string)
  default = {}
}

# --- Outputs ---

output "group_name" {
  value = oci_identity_group.github_actions.name
}

output "policy_name" {
  value = oci_identity_policy.github_actions_terraform.name
}
