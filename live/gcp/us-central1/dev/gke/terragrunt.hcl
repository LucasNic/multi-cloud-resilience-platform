# ⚠️⚠️⚠️ ATENÇÃO: RECURSOS DESTRUÍDOS - NÃO CRIAR NOVAMENTE ⚠️⚠️⚠️
# O cluster GKE foi destruído para evitar custos.
# Esta configuração está comentada para prevenir que a pipeline recrie os recursos.
# Para referência histórica apenas.

/*
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
*/
