# locals {
#   rule_sets = {
#     for rule_set, rule_config in try(var.rule_sets, {}) : rule_set => rule_config
#   }
# }

resource "azurerm_cdn_frontdoor_rule_set" "main" {
  for_each = try(var.rule_sets, {})

  name                     = each.key
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
}

locals {
  rules = {
    for rule in flatten([
      for rule_set_name, rule_set_config in try(var.rule_sets, {}) : [
        for rule_name, rule_config in rule_set_config.rules : [
          merge(
            {
              #  all defaults go here
              order             = 1
              behavior_on_match = "Continue"
              actions           = {}
              conditions        = {}
            },
            rule_config,
            {
              set_name     = rule_set_name
              name         = rule_name
              origin_group = rule_config.origin_group
              actions = {
                route_configuration_override_action = can(rule_config.actions.route_configuration_override_action) ? merge(
                  {
                    origin_group                  = rule_config.origin_group
                    forwarding_protocol           = "HttpsOnly"
                    query_string_caching_behavior = "IncludeSpecifiedQueryStrings"
                    query_string_parameters       = []
                    compression_enabled           = true
                    cache_behavior                = "OverrideIfOriginMissing"
                    cache_duration                = "365.23:59:59"
                  },
                rule_config.actions.route_configuration_override_action) : null

                # url redirection configuration starts here
                url_redirect_action = can(rule_config.actions.url_redirect_action) ? merge(
                  {
                    destination_hostname = ""
                    redirect_type        = "PermanentRedirect"
                    redirect_protocol    = "MatchRequest"
                    query_string         = ""
                    destination_path     = ""
                    destination_fragment = ""
                  },
                rule_config.actions.url_redirect_action) : null

                # url url_rewrite_action configuration starts here
                url_rewrite_action = can(rule_config.actions.url_rewrite_action) ? merge(
                  {
                    source_pattern          = ""
                    destination             = ""
                    preserve_unmatched_path = false
                  },
                rule_config.actions.url_rewrite_action) : null

                # url request_header_action configuration starts here
                request_header_action = can(rule_config.actions.request_header_action) ? merge(
                  {
                    header_action = ""
                    header_name   = ""
                    value         = ""
                  },
                rule_config.actions.request_header_action) : null

                # url response_header_action configuration starts here
                response_header_action = can(rule_config.actions.response_header_action) ? merge(
                  {
                    header_action = ""
                    header_name   = ""
                    value         = ""
                  },
                rule_config.actions.response_header_action) : null
              }
              conditions = {}
            }
          )
        ]
    ]]) : "${rule.set_name}${rule.name}" => rule
  }
}

output "actions" {
  # value = local.rules["usrulescaliforniarule"].actions
  value = local.rules["usrulescaliforniarule"].actions
  # value = "good"
}

resource "azurerm_cdn_frontdoor_rule" "main" {
  for_each = local.rules

  name                      = each.key
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.main[each.value.set_name].id
  order                     = each.value.order
  behavior_on_match         = each.value.behavior_on_match

  actions {
    dynamic "route_configuration_override_action" {
      for_each = each.value.actions.route_configuration_override_action != null ? [each.value.actions.route_configuration_override_action] : []
      content {
        cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main[route_configuration_override_action.value.origin_group].id
        forwarding_protocol           = route_configuration_override_action.value.forwarding_protocol
        query_string_caching_behavior = route_configuration_override_action.value.query_string_caching_behavior
        query_string_parameters       = route_configuration_override_action.value.query_string_parameters
        compression_enabled           = route_configuration_override_action.value.compression_enabled
        cache_behavior                = route_configuration_override_action.value.cache_behavior
        cache_duration                = route_configuration_override_action.value.cache_duration
      }
    }
    dynamic "url_redirect_action" {
      for_each = each.value.actions.url_redirect_action != null ? [each.value.actions.url_redirect_action] : []
      content {
        destination_hostname = url_redirect_action.value.destination_hostname
        redirect_type        = url_redirect_action.value.redirect_type
        redirect_protocol    = url_redirect_action.value.redirect_protocol
        query_string         = url_redirect_action.value.query_string
        destination_path     = url_redirect_action.value.destination_path
        destination_fragment = url_redirect_action.value.destination_fragment
      }
    }
    dynamic "url_rewrite_action" {
      for_each = each.value.actions.url_rewrite_action != null ? [each.value.actions.url_rewrite_action] : []
      content {
        source_pattern          = url_rewrite_action.value.source_pattern
        destination             = url_rewrite_action.value.destination
        preserve_unmatched_path = url_rewrite_action.value.preserve_unmatched_path
      }
    }
    dynamic "request_header_action" {
      for_each = each.value.actions.request_header_action != null ? [each.value.actions.request_header_action] : []
      content {
        header_action = request_header_action.value.header_action
        header_name   = request_header_action.value.header_name
        value         = request_header_action.value.value
      }
    }
    dynamic "response_header_action" {
      for_each = each.value.actions.response_header_action != null ? [each.value.actions.response_header_action] : []
      content {
        header_action = response_header_action.value.header_action
        header_name   = response_header_action.value.header_name
        value         = response_header_action.value.value
      }
    }
  }

  conditions {
    host_name_condition {
      operator         = "Equal"
      negate_condition = false
      match_values     = ["www.contoso.com", "images.contoso.com", "video.contoso.com"]
      transforms       = ["Lowercase", "Trim"]
    }

    #     is_device_condition {
    #       operator         = "Equal"
    #       negate_condition = false
    #       match_values     = ["Mobile"]
    #     }

    #     post_args_condition {
    #       post_args_name = "customerName"
    #       operator       = "BeginsWith"
    #       match_values   = ["J", "K"]
    #       transforms     = ["Uppercase"]
    #     }

    #     request_method_condition {
    #       operator         = "Equal"
    #       negate_condition = false
    #       match_values     = ["DELETE"]
    #     }

    #     url_filename_condition {
    #       operator         = "Equal"
    #       negate_condition = false
    #       match_values     = ["media.mp4"]
    #       transforms       = ["Lowercase", "RemoveNulls", "Trim"]
    #     }
  }

  depends_on = [
    azurerm_cdn_frontdoor_origin_group.main,
    azurerm_cdn_frontdoor_origin.main
  ]
}
