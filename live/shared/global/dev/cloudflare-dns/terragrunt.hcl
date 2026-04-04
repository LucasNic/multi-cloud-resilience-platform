include "root" {
  path = find_in_parent_folders()
}

dependency "aks" {
  config_path = "../../../../azure/eastus/dev/aks"
}

dependency "gke" {
  config_path = "../../../../gcp/us-central1/dev/gke"
}

terraform {
  source = "../../../../../modules/shared/cloudflare-dns"
}

inputs = {
  cloudflare_account_id = get_env("CLOUDFLARE_ACCOUNT_ID")
  cloudflare_api_token  = get_env("CLOUDFLARE_API_TOKEN")
  domain_name           = "lucasnicoloso.com"
  aks_ingress_ip        = dependency.aks.outputs.cluster_endpoint
  gke_ingress_ip        = dependency.gke.outputs.cluster_endpoint
  failure_threshold     = 3
}
