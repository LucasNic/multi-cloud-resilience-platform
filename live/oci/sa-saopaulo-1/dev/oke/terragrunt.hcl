include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../modules/oci/oke"
}

inputs = {
  compartment_id           = get_env("OCI_COMPARTMENT_ID")
  availability_domain      = get_env("OCI_AVAILABILITY_DOMAIN")
  object_storage_namespace = get_env("OCI_NAMESPACE")

  # ARM A1 free tier: 2 nodes × 2 OCPU + 12GB = 4 OCPU / 24GB total
  # Split across 2 nodes to increase chance of capacity allocation
  # (OCI "Out of host capacity" is per-instance, not per-tenancy)
  node_count     = 2
  node_ocpus     = 2
  node_memory_gb = 12
}
