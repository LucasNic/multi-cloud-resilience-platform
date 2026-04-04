include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../modules/azure/networking"
}

inputs = {
  location = "eastus"
}
