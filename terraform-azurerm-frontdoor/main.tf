resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = var.frontdoor_profile.name
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = var.frontdoor_profile.sku_name
  tags                = var.frontdoor_profile.tags
}

locals {
  origin_groups = {
    for group_key, group_config in try(var.origin_groups, {}) : group_key => merge(
      {
        #defaults go here
        session_affinity_enabled = false
        restore_traffic_time     = 10
      },
      group_config,
      {
        # this is the default health_proble.
        health_probe = merge({
          interval_in_seconds = 240
          path                = "/"
          protocol            = "Https"
          request_type        = "HEAD"
          }, try(group_config.health_probe, {})
        )
        # this is the default load_balancing.
        load_balancing = merge({
          latency_in_milliseconds = 0
          sample_size             = 16
          sample_required         = 3
          }, try(group_config.load_balancing, {})
        )
    })
  }
}

resource "azurerm_cdn_frontdoor_origin_group" "main" {
  for_each = local.origin_groups

  name                     = each.key
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  session_affinity_enabled = each.value.session_affinity_enabled

  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = each.value.restore_traffic_time

  health_probe {
    interval_in_seconds = each.value.health_probe.interval_in_seconds
    path                = each.value.health_probe.path
    protocol            = each.value.health_probe.protocol
    request_type        = each.value.health_probe.request_type
  }

  load_balancing {
    additional_latency_in_milliseconds = each.value.load_balancing.latency_in_milliseconds
    sample_size                        = each.value.load_balancing.sample_size
    successful_samples_required        = each.value.load_balancing.sample_required
  }
}

locals {
  origin_list = {
    for origin_key, origin_config in try(var.origin_list, {}) : origin_key => merge(
      {
        origin_group                   = origin_config.origin_group_name
        enabled                        = true
        certificate_name_check_enabled = false
        http_port                      = 80
        https_port                     = 443
        origin_host_header             = null
        priority                       = 1
        weight                         = 1
      },
      origin_config,
      {
        # this logic captures the origin group name where the origin is associated with.
        # this avoid logics in the resource definition
      }
    )
  }
}

resource "azurerm_cdn_frontdoor_origin" "main" {
  for_each = local.origin_list

  name                           = each.key
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.main[each.value.origin_group].id
  enabled                        = each.value.enabled
  certificate_name_check_enabled = each.value.certificate_name_check_enabled

  host_name          = each.value.host_name
  http_port          = each.value.http_port
  https_port         = each.value.https_port
  origin_host_header = each.value.origin_host_header
  priority           = each.value.priority
  weight             = each.value.weight
}
