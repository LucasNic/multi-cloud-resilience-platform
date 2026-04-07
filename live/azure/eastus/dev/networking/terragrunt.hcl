# ⚠️ ATENÇÃO: DEPLOY DESATIVADO PARA EVITAR CUSTOS ⚠️
# Esta configuração foi desativada para evitar custos inesperados na GCP/Azure.
# O projeto multi-cloud agora é apenas uma demonstração visual hospedada no Cloudflare Pages.
# NÃO execute terragrunt apply - use apenas para referência ou destruição de recursos existentes.
# Para destruir recursos: terragrunt destroy
# Repositório da simulação visual: https://github.com/LucasNic/multi-cloud-simulation

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../modules/azure/networking"
}

inputs = {
  location = "eastus"
}
