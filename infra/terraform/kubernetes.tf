resource "azurerm_container_registry" "example" {
  count               = local.deploy_acr ? 1 : 0
  name                = "acr${local.name}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Premium"
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "aks-${local.name}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "aks-${local.name}"

  default_node_pool {
    name       = "system"
    vm_size    = "Standard_D4s_v4"
    node_count = 3
  }

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  monitor_metrics {
  }
  
  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.example.id
    msi_auth_for_monitoring_enabled = true
  }

  lifecycle {
    ignore_changes = [
      monitor_metrics,
      azure_policy_enabled,
      microsoft_defender
    ]
  }
}

resource "azurerm_role_assignment" "example" {
  count                            = local.deploy_acr ? 1 : 0
  principal_id                     = azurerm_kubernetes_cluster.example.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.example[0].id
  skip_service_principal_aad_check = true
}