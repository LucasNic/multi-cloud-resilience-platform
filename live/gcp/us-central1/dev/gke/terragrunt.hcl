# ⚠️ ATENÇÃO: DEPLOY DESATIVADO PARA EVITAR CUSTOS ⚠️
# Esta configuração foi desativada para evitar custos inesperados na GCP/Azure.
# O projeto multi-cloud agora é apenas uma demonstração visual hospedada no Cloudflare Pages.
# NÃO execute terragrunt apply - use apenas para referência ou destruição de recursos existentes.
# Para destruir recursos: terragrunt destroy
# Repositório da simulação visual: https://github.com/LucasNic/multi-cloud-simulation

include "root" {
  path = find_in_parent_folders()
}

dependency "networking" {
  config_path = "../networking"
  skip_outputs = true
}

terraform {
  source = "../../../../../modules/gcp/gke"
}

inputs = {
  gcp_project_id      = get_env("GCP_PROJECT_ID")
  zone                = "us-central1-a"
  # Usando valores hardcoded para destruição já que os outputs do networking não estão disponíveis
  vpc_name            = "multicloud-dev-vpc"
  subnet_name         = "multicloud-dev-gke-subnet"
  pods_range_name     = "gke-pods"
  services_range_name = "gke-services"
  node_count          = 1
}
