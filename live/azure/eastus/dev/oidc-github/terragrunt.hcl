include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../modules/azure/oidc-github"
}

inputs = {
  github_repo   = "LucasNic/multi-cloud-resilience-platform"
  github_branch = "main"
}
