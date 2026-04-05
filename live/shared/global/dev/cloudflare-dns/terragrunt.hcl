include "root" {
  path = find_in_parent_folders()
}

dependency "azure_networking" {
  config_path = "../../../../azure/eastus/dev/networking"
}

dependency "gcp_networking" {
  config_path = "../../../../gcp/us-central1/dev/networking"
}

terraform {
  source = "../../../../../modules/shared/cloudflare-dns"
}

inputs = {
  cloudflare_account_id = get_env("CLOUDFLARE_ACCOUNT_ID")
  cloudflare_api_token  = get_env("CLOUDFLARE_API_TOKEN")
  domain_name           = "lucasnicoloso.com"
  aks_ingress_ip        = dependency.azure_networking.outputs.aks_ingress_ip
  gke_ingress_ip        = dependency.gcp_networking.outputs.gke_ingress_ip
  failure_threshold     = 3
}
