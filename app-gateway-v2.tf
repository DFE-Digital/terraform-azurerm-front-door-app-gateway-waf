resource "azurerm_user_assigned_identity" "app_gateway" {
  count = local.app_gateway_v2_create_identity ? 1 : 0

  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  name                = "${local.resource_prefix}-app-gateway"
}

resource "azurerm_key_vault" "app_gateway_certificates" {
  count = local.waf_application == "AppGatewayV2" && local.enable_key_vault_app_gateway_certificates ? 1 : 0

  name                       = "${local.resource_prefix}-agcerts"
  location                   = local.resource_group.location
  resource_group_name        = local.resource_group.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  enable_rbac_authorization  = local.key_vault_app_gateway_enable_rbac
  purge_protection_enabled   = true

  dynamic "access_policy" {
    for_each = data.azuread_user.key_vault_app_gateway_certificates_access

    content {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = access_policy.value["object_id"]

      secret_permissions = [
        "Get"
      ]

      certificate_permissions = [
        "Backup",
        "Create",
        "Delete",
        "Get",
        "Import",
        "List",
        "Purge",
        "Recover",
        "Restore",
        "Update",
      ]
    }
  }

  dynamic "access_policy" {
    for_each = local.app_gateway_v2_identity_principle_ids

    content {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = access_policy.value

      secret_permissions = [
        "Get"
      ]
    }
  }

  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = length(local.key_vault_app_gateway_certificates_access_ipv4) > 0 ? local.key_vault_app_gateway_certificates_access_ipv4 : null
    virtual_network_subnet_ids = length(local.key_vault_app_gateway_certificates_access_subnet_ids) > 0 ? local.key_vault_app_gateway_certificates_access_subnet_ids : null
  }

  tags = local.tags
}

resource "azurerm_role_assignment" "app_gateway_certificates" {
  for_each = local.key_vault_app_gateway_enable_rbac ? toset(local.app_gateway_v2_identity_principle_ids) : []

  scope                = azurerm_key_vault.app_gateway_certificates[0].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}

resource "azurerm_application_gateway" "waf" {
  count = local.waf_application == "AppGatewayV2" ? 1 : 0

  name                = "${local.resource_prefix}-waf"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  zones               = local.app_gateway_v2_availability_zones
  enable_http2        = local.app_gateway_v2_enable_http2

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = local.app_gateway_v2_capacity_units
  }

  gateway_ip_configuration {
    name      = "default-gateway-ip-configuration"
    subnet_id = azurerm_subnet.app_gateway_v2_subnet[0].id
  }

  frontend_port {
    name = "http"
    port = local.app_gateway_v2_frontend_port
  }

  frontend_ip_configuration {
    name                            = "default-frontend"
    public_ip_address_id            = azurerm_public_ip.app_gateway_v2[0].id
    private_link_configuration_name = local.app_gateway_v2_enable_private_link ? "${local.resource_prefix}-waf" : null
  }

  frontend_ip_configuration {
    name                          = "private-frontend"
    private_ip_address_allocation = "Static"
    private_ip_address            = local.app_gateway_v2_private_ip
    subnet_id                     = azurerm_subnet.app_gateway_v2_subnet[0].id
  }

  dynamic "backend_address_pool" {
    for_each = local.waf_targets

    content {
      name  = backend_address_pool.key
      fqdns = [backend_address_pool.value["domain"]]
    }
  }

  dynamic "probe" {
    for_each = local.waf_targets

    content {
      name                = probe.key
      timeout             = 60
      unhealthy_threshold = 5
      host                = probe.value["domain"]
      interval            = probe.value["health_probe_interval"]
      path                = probe.value["health_probe_path"]
      protocol            = "Https"
      match {
        status_code = ["200-499"]
      }
    }
  }

  dynamic "backend_http_settings" {
    for_each = local.waf_targets

    content {
      name                                = backend_http_settings.key
      cookie_based_affinity               = local.app_gateway_v2_cookie_based_affinity
      path                                = "/"
      port                                = 443
      protocol                            = "Https"
      request_timeout                     = local.response_request_timeout
      pick_host_name_from_backend_address = backend_http_settings.app_gateway_v2_use_backend_hostname
      probe_name                          = backend_http_settings.key
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = local.app_gateway_v2_identity_ids
  }

  dynamic "custom_error_configuration" {
    for_each = local.app_gateway_v2_custom_error_configuration

    content {
      status_code           = custom_error_configuration.key
      custom_error_page_url = custom_error_configuration.value
    }
  }

  dynamic "http_listener" {
    for_each = local.waf_targets

    content {
      name                           = http_listener.key
      host_name                      = http_listener.value["domain"]
      frontend_ip_configuration_name = http_listener.value["app_gateway_v2_use_private_listener"] ? "private-frontend" : "default-frontend"
      frontend_port_name             = "http"
      protocol                       = "Http"

      dynamic "custom_error_configuration" {
        for_each = http_listener.value["custom_errors"] != null ? http_listener.value["custom_errors"]["error_pages"] : {}

        content {
          status_code           = custom_error_configuration.key
          custom_error_page_url = "${azurerm_storage_account.custom_error[http_listener.key].primary_web_endpoint}${custom_error_configuration.value}"
        }
      }
    }
  }

  dynamic "request_routing_rule" {
    for_each = local.waf_targets

    content {
      name                       = request_routing_rule.key
      rule_type                  = "Basic"
      http_listener_name         = request_routing_rule.key
      backend_address_pool_name  = request_routing_rule.key
      backend_http_settings_name = request_routing_rule.key
      priority                   = index(keys(local.waf_targets), request_routing_rule.key) + 1
    }
  }

  dynamic "private_link_configuration" {
    for_each = local.app_gateway_v2_enable_private_link ? [1] : []

    content {
      name = "${local.resource_prefix}-waf"

      ip_configuration {
        name                          = "default-frontend"
        subnet_id                     = azurerm_subnet.app_gateway_v2_subnet_private_link[0].id
        private_ip_address_allocation = "Dynamic"
        primary                       = true
      }
    }
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.waf[0].id
  tags               = local.tags
}
