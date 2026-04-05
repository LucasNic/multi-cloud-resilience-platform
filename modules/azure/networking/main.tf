###############################################################################
# Azure Networking — VNet for AKS Primary Cluster
#
# Minimal VNet for the AKS primary cluster.
# Subnet sizing follows Azure AKS networking best practices:
# - Node subnet: /20 (4096 IPs)
# - Pod subnet (Azure CNI overlay): no extra subnet needed
###############################################################################

resource "azurerm_resource_group" "main" {
  name     = "${var.project_prefix}-${var.environment}-rg"
  location = var.location

  tags = local.common_tags
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.project_prefix}-${var.environment}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]

  tags = local.common_tags
}

resource "azurerm_subnet" "aks" {
  name                 = "${var.project_prefix}-${var.environment}-aks-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/20"]
}

# --- NSG: allow HTTPS inbound (health checks + traffic) ---

resource "azurerm_network_security_group" "aks" {
  name                = "${var.project_prefix}-${var.environment}-aks-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "80"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# --- Static Public IP for AKS ingress ---
# Created here (main RG) so it can be referenced before AKS is deployed.
# AKS ingress controller uses this via service annotation:
#   service.beta.kubernetes.io/azure-load-balancer-resource-group: <rg>
#   spec.loadBalancerIP: <this IP>

resource "azurerm_public_ip" "aks_ingress" {
  name                = "${var.project_prefix}-${var.environment}-aks-ingress-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

# --- Locals ---

locals {
  common_tags = merge(
    {
      project     = var.project_prefix
      environment = var.environment
      managed_by  = "terraform"
      module      = "azure-networking"
    },
    var.extra_tags
  )
}

# --- Variables ---

variable "project_prefix" { type = string }
variable "environment" {
  type    = string
  default = "dev"
}
variable "location" {
  type    = string
  default = "eastus"
}
variable "extra_tags" {
  type    = map(string)
  default = {}
}

# --- Outputs ---

output "resource_group_name" { value = azurerm_resource_group.main.name }
output "resource_group_id" { value = azurerm_resource_group.main.id }
output "vnet_name" { value = azurerm_virtual_network.main.name }
output "vnet_id" { value = azurerm_virtual_network.main.id }
output "aks_subnet_id" { value = azurerm_subnet.aks.id }
output "aks_subnet_name" { value = azurerm_subnet.aks.name }
output "location" { value = azurerm_resource_group.main.location }
output "aks_ingress_ip" {
  description = "Static public IP for AKS ingress LoadBalancer"
  value       = azurerm_public_ip.aks_ingress.ip_address
}
output "aks_ingress_pip_id" {
  description = "Resource ID of the AKS ingress public IP"
  value       = azurerm_public_ip.aks_ingress.id
}
