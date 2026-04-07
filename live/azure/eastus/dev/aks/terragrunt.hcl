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
}

terraform {
  source = "../../../../../modules/azure/aks"
}

inputs = {
  location            = "eastus"
  resource_group_name = dependency.networking.outputs.resource_group_name
  aks_subnet_id       = dependency.networking.outputs.aks_subnet_id
  node_count          = 1
}
