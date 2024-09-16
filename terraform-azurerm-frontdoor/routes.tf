locals {
  endpoints = {
    for endpoint in try(var.endpoints, []) : endpoint => {}
  }
}

resource "azurerm_cdn_frontdoor_endpoint" "all" {
  for_each                 = local.endpoints
  name                     = each.key
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

locals {
  routes = {
    for route, route_config in try(var.routes, {}) : route => merge(
      {
        # defaults go here
        enabled                = true
        forwarding_protocol    = "HttpsOnly"
        https_redirect_enabled = true
        patterns_to_match      = ["/*"]
        supported_protocols    = ["Http", "Https"]

        # cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.main[*].id]
        link_to_default_domain = false
      },
      route_config,
      {
        # customization and gathering data
        endpoint_name     = route_config.endpoint
        origin_group_name = route_config.origin_group
        origin_list       = route_config.origin_list
        custom_domains = [
          for domain in local.custom_domains : {
            custom_domain_key = "${domain.subdomain}-${domain.dns_zone_key}"
          } if domain.route == route
        ]
        rule_sets = try(local.rule_sets, [])

        cache = merge({
          # This is default values, then merging with proposed
          query_string_caching_behavior = "IgnoreQueryString"
          query_strings                 = []
          compression_enabled           = false
          content_types_to_compress     = []
          link_to_default_domain        = false
          },
          try(route_config.cache, {})
        )
      }
    )
  }
}

resource "azurerm_cdn_frontdoor_route" "all" {
  for_each = local.routes

  name                          = each.key
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.all[each.value.endpoint].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main[each.value.origin_group_name].id

  cdn_frontdoor_origin_ids        = [for origin in each.value.origin_list : azurerm_cdn_frontdoor_origin.main[origin].id]
  cdn_frontdoor_custom_domain_ids = [for custom in each.value.custom_domains : azurerm_cdn_frontdoor_custom_domain.main[custom.custom_domain_key].id]
  # cdn_frontdoor_rule_set_ids      = [for rule_set in each.value.rule_sets : azurerm_cdn_frontdoor_rule_set.main[rule_set].id]

  enabled                = each.value.enabled
  forwarding_protocol    = each.value.forwarding_protocol
  https_redirect_enabled = each.value.https_redirect_enabled
  patterns_to_match      = each.value.patterns_to_match
  supported_protocols    = each.value.supported_protocols
  link_to_default_domain = each.value.link_to_default_domain

  cache {
    query_string_caching_behavior = each.value.cache.query_string_caching_behavior
    query_strings                 = each.value.cache.query_strings
    compression_enabled           = each.value.cache.compression_enabled
    content_types_to_compress     = each.value.cache.content_types_to_compress
  }
}

