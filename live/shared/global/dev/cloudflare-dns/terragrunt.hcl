# ⚠️ ATENÇÃO: DEPLOY DESATIVADO PARA EVITAR CUSTOS ⚠️
# Esta configuração foi desativada para evitar custos inesperados na GCP/Azure.
# O projeto multi-cloud agora é apenas uma demonstração visual hospedada no Cloudflare Pages.
# NÃO execute terragrunt apply - use apenas para referência ou destruição de recursos existentes.
# Para destruir recursos: terragrunt destroy
# Repositório da simulação visual: https://github.com/LucasNic/multi-cloud-simulation

include "root" {
  path = find_in_parent_folders()
}

dependency "azure_networking" {
  config_path = "../../../../azure/eastus/dev/networking"
  skip_outputs = true
  mock_outputs = {
    aks_ingress_ip    = "0.0.0.0"
    aks_ingress_pip_id = "/subscriptions/mock/resourceGroups/mock/providers/Microsoft.Network/publicIPAddresses/mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "gcp_networking" {
  config_path = "../../../../gcp/us-central1/dev/networking"
  skip_outputs = true
  mock_outputs = {
    gke_ingress_ip = "0.0.0.0"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

terraform {
  source = "../../../../../modules/shared/cloudflare-dns"
}

inputs = {
  cloudflare_account_id = get_env("CLOUDFLARE_ACCOUNT_ID")
  cloudflare_api_token  = get_env("CLOUDFLARE_API_TOKEN")
  domain_name           = "lucasnicoloso.com"
  # Usando valores hardcoded porque os módulos de networking foram destruídos/desativados
  aks_ingress_ip        = "20.72.144.57"  # IP do AKS (pode não existir mais)
  gke_ingress_ip        = "34.27.20.121"  # IP do GKE (pode não existir mais)
  app_ingress_ip        = "20.72.144.57"  # IP do AKS (mesmo que aks_ingress_ip)
  # Root domain points to portfolio on Cloudflare Pages
  root_cname_target     = "lucasnicoloso-com.pages.dev"
  failure_threshold     = 3
  worker_secret         = get_env("WORKER_SECRET")
}
