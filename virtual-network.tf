resource "azurerm_virtual_network" "default" {
  count = local.create_virtual_network ? 1 : 0

  name                = "${local.resource_prefix}default"
  address_space       = [local.virtual_network_address_space]
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  tags                = local.tags
}

resource "azurerm_route_table" "default" {
  count = local.create_virtual_network ? 1 : 0

  name                = "${local.resource_prefix}default"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  tags                = local.tags
}

resource "azurerm_subnet" "app_gateway_v2_subnet" {
  count = local.create_virtual_network && local.waf_application == "AppGatewayV2" ? 1 : 0

  name                 = "${local.resource_prefix}app-gateway-v2"
  virtual_network_name = local.virtual_network_name
  resource_group_name  = local.resource_group.name
  address_prefixes     = [local.app_gateway_v2_subnet_cidr]

  depends_on = [
    azurerm_virtual_network.default[0]
  ]
}

resource "azurerm_subnet_route_table_association" "app_gateway_v2_subnet" {
  count = local.create_virtual_network && local.waf_application == "AppGatewayV2" ? 1 : 0

  subnet_id      = azurerm_subnet.app_gateway_v2_subnet[0].id
  route_table_id = azurerm_route_table.default[0].id
}

resource "azurerm_network_security_group" "app_gateway_v2_allow_frontdoor_inbound_only" {
  count = local.create_virtual_network && local.waf_application == "AppGatewayV2" ? 1 : 0

  name                = "${local.resource_prefix}appgatewayv2sg"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  dynamic "security_rule" {
    for_each = local.restrict_app_gateway_v2_to_front_door_inbound_only ? [1] : []

    content {
      name                         = "AllowFrontdoor"
      description                  = "Azure Front Door entrypoint: Allow incoming traffic from the AzureFrontDoor.Backend service tag to HTTP/HTTPS destination"
      priority                     = 100
      direction                    = "Inbound"
      access                       = "Allow"
      protocol                     = "Tcp"
      source_address_prefix        = "AzureFrontDoor.Backend"
      source_port_range            = "*"
      destination_port_ranges      = [80, 443]
      destination_address_prefix   = local.restrict_app_gateway_v2_to_front_door_inbound_only_destination_prefix
      destination_address_prefixes = local.restrict_app_gateway_v2_to_front_door_inbound_only_destination_prefixes
    }
  }

  security_rule {
    name                       = "AllowAppGatewayServices"
    description                = "Infrastructure ports: Allow incoming requests from the GatewayManager service tag and Any destination"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "GatewayManager"
    destination_port_range     = "65200-65535"
    destination_address_prefix = "*"
  }

  tags = local.tags
}

resource "azurerm_subnet_network_security_group_association" "app_gateway_v2_allow_frontdoor_inbound_only" {
  count = local.create_virtual_network && local.waf_application == "AppGatewayV2" && local.restrict_app_gateway_v2_to_front_door_inbound_only ? 1 : 0

  subnet_id                 = azurerm_subnet.app_gateway_v2_subnet[0].id
  network_security_group_id = azurerm_network_security_group.app_gateway_v2_allow_frontdoor_inbound_only[0].id
}

resource "azurerm_public_ip" "app_gateway_v2" {
  count = local.create_virtual_network && local.waf_application == "AppGatewayV2" ? 1 : 0

  name                = "${local.resource_prefix}appgatewayv2"
  resource_group_name = local.resource_group.name
  location            = local.resource_group.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.tags
}

resource "azurerm_virtual_network_peering" "source_to_origin" {
  for_each = local.virtual_network_peering_targets

  name                      = "Vnet-${azurerm_virtual_network.default[0].name}-To-Vnet-${data.azurerm_virtual_network.vnet[each.key].name}"
  resource_group_name       = local.resource_group.name
  virtual_network_name      = azurerm_virtual_network.default[0].name
  remote_virtual_network_id = data.azurerm_virtual_network.vnet[each.key].id
}
