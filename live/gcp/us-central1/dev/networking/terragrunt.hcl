# ⚠️⚠️⚠️ ATENÇÃO: RECURSOS DESTRUÍDOS - NÃO CRIAR NOVAMENTE ⚠️⚠️⚠️
# A rede VPC da GCP foi destruída para evitar custos.
# Esta configuração está comentada para prevenir que a pipeline recrie os recursos.
# Para referência histórica apenas.

/*
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../modules/gcp/networking"
}

inputs = {
  gcp_project_id = get_env("GCP_PROJECT_ID")
}
*/
