locals {
  dns_zones = {
    for zone in try(var.dns_zones, []) : replace(zone, ".", "-") => zone
  }
}
resource "azurerm_dns_zone" "main" {
  for_each = local.dns_zones

  name                = each.value
  resource_group_name = azurerm_resource_group.main.name
}

locals {
  custom_domains = {
    for element in flatten([
      for custom in var.custom_domains : [
        for subdomain in custom.domains : [
          merge(
            {
              subdomain    = subdomain
              dns_zone     = custom.dns_zone
              route        = custom.route
              dns_zone_key = replace(custom.dns_zone, ".", "-")
            },
            custom,
            {
              tls = merge(
                {
                  certificate_type    = "ManagedCertificate"
                  minimum_tls_version = "TLS12"
                },
                try(custom.tls, {})
              )
            }
          )
        ]
    ]]) : "${element.subdomain}-${element.dns_zone_key}" => element
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "main" {
  for_each = local.custom_domains

  name                     = each.key
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  dns_zone_id              = azurerm_dns_zone.main[each.value.dns_zone_key].id
  host_name                = join(".", [each.value.subdomain, azurerm_dns_zone.main[each.value.dns_zone_key].name])

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "main" {
  for_each = local.custom_domains

  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.main["${each.value.subdomain}-${each.value.dns_zone_key}"].id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.all[each.value.route].id]
}
