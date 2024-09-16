locals {
  rule_sets = {
    for rule_set, rule_config in try(var.rule_sets, {}) : rule_set => rule_config
  }
}

resource "azurerm_cdn_frontdoor_rule_set" "main" {
  for_each                 = local.rule_sets
  
  name                     = each.key
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}
