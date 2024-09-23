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
              conditions = {
                for condition, condition_body in try(rule_config.conditions, {}) : condition => merge(
                  {
                    #defaults go here
                    operator         = ""
                    negate_condition = false
                    match_values     = []
                    transforms       = []
                    post_args_name   = ""
                    cookie_name      = ""
                }, condition_body) if try(rule_config.conditions, {}) != {}
              }
            }
          )
        ]
    ]]) : "${rule.set_name}${rule.name}" => rule
  }
}

output "actions" {
  value = local.rules["usrulescaliforniarule"].conditions
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
    dynamic "remote_address_condition" {
      for_each = can(each.value.conditions.remote_address_condition) ? [each.value.conditions.remote_address_condition] : []
      content {
        operator         = remote_address_condition.value.operator
        negate_condition = remote_address_condition.value.negate_condition
        match_values     = remote_address_condition.value.match_values
      }
    }
    dynamic "request_method_condition" {
      for_each = can(each.value.conditions.request_method_condition) ? [each.value.conditions.request_method_condition] : []
      content {
        operator         = request_method_condition.value.operator
        negate_condition = request_method_condition.value.negate_condition
        match_values     = request_method_condition.value.match_values
      }
    }
    dynamic "query_string_condition" {
      for_each = can(each.value.conditions.query_string_condition) ? [each.value.conditions.query_string_condition] : []
      content {
        operator         = query_string_condition.value.operator
        negate_condition = query_string_condition.value.negate_condition
        match_values     = query_string_condition.value.match_values
        transforms       = query_string_condition.value.transforms
      }
    }
    dynamic "post_args_condition" {
      for_each = can(each.value.conditions.post_args_condition) ? [each.value.conditions.post_args_condition] : []
      content {
        post_args_name   = post_args_condition.value.post_args_name
        operator         = post_args_condition.value.operator
        negate_condition = post_args_condition.value.negate_condition
        match_values     = post_args_condition.value.match_values
        transforms       = post_args_condition.value.transforms
      }
    }
    dynamic "request_uri_condition" {
      for_each = can(each.value.conditions.request_uri_condition) ? [each.value.conditions.request_uri_condition] : []
      content {
        operator         = request_uri_condition.value.operator
        negate_condition = request_uri_condition.value.negate_condition
        match_values     = request_uri_condition.value.match_values
        transforms       = request_uri_condition.value.transforms
      }
    }
    dynamic "request_header_condition" {
      for_each = can(each.value.conditions.request_header_condition) ? [each.value.conditions.request_header_condition] : []
      content {
        header_name      = request_header_condition.value.header_name
        operator         = request_header_condition.value.operator
        negate_condition = request_header_condition.value.negate_condition
        match_values     = request_header_condition.value.match_values
        transforms       = request_header_condition.value.transforms
      }
    }
    dynamic "request_body_condition" {
      for_each = can(each.value.conditions.request_body_condition) ? [each.value.conditions.request_body_condition] : []
      content {
        operator         = request_body_condition.value.operator
        negate_condition = request_body_condition.value.negate_condition
        match_values     = request_body_condition.value.match_values
        transforms       = request_body_condition.value.transforms
      }
    }
    dynamic "request_scheme_condition" {
      for_each = can(each.value.conditions.request_scheme_condition) ? [each.value.conditions.request_scheme_condition] : []
      content {
        operator         = request_scheme_condition.value.operator
        negate_condition = request_scheme_condition.value.negate_condition
        match_values     = request_scheme_condition.value.match_values
      }
    }
    dynamic "url_path_condition" {
      for_each = can(each.value.conditions.url_path_condition) ? [each.value.conditions.url_path_condition] : []
      content {
        operator         = url_path_condition.value.operator
        negate_condition = url_path_condition.value.negate_condition
        match_values     = url_path_condition.value.match_values
      }
    }
    dynamic "url_file_extension_condition" {
      for_each = can(each.value.conditions.url_file_extension_condition) ? [each.value.conditions.url_file_extension_condition] : []
      content {
        operator         = url_file_extension_condition.value.operator
        negate_condition = url_file_extension_condition.value.negate_condition
        match_values     = url_file_extension_condition.value.match_values
      }
    }
    dynamic "url_filename_condition" {
      for_each = can(each.value.conditions.url_filename_condition) ? [each.value.conditions.url_filename_condition] : []
      content {
        operator         = url_filename_condition.value.operator
        negate_condition = url_filename_condition.value.negate_condition
        match_values     = url_filename_condition.value.match_values
      }
    }
    dynamic "http_version_condition" {
      for_each = can(each.value.conditions.http_version_condition) ? [each.value.conditions.http_version_condition] : []
      content {
        operator         = http_version_condition.value.operator
        negate_condition = http_version_condition.value.negate_condition
        match_values     = http_version_condition.value.match_values
      }
    }
    dynamic "cookies_condition" {
      for_each = can(each.value.conditions.cookies_condition) ? [each.value.conditions.cookies_condition] : []
      content {
        cookie_name      = cookies_condition.value.cookie_name
        operator         = cookies_condition.value.operator
        negate_condition = cookies_condition.value.negate_condition
        match_values     = cookies_condition.value.match_values
        transforms       = cookies_condition.value.transforms
      }
    }
    dynamic "is_device_condition" {
      for_each = can(each.value.conditions.is_device_condition) ? [each.value.conditions.is_device_condition] : []
      content {
        operator         = is_device_condition.value.operator
        negate_condition = is_device_condition.value.negate_condition
        match_values     = is_device_condition.value.match_values
      }
    }
    dynamic "socket_address_condition" {
      for_each = can(each.value.conditions.socket_address_condition) ? [each.value.conditions.socket_address_condition] : []
      content {
        operator         = socket_address_condition.value.operator
        negate_condition = socket_address_condition.value.negate_condition
        match_values     = socket_address_condition.value.match_values
      }
    }
    dynamic "client_port_condition" {
      for_each = can(each.value.conditions.client_port_condition) ? [each.value.conditions.client_port_condition] : []
      content {
        operator         = client_port_condition.value.operator
        negate_condition = client_port_condition.value.negate_condition
        match_values     = client_port_condition.value.match_values
      }
    }
    dynamic "host_name_condition" {
      for_each = can(each.value.conditions.host_name_condition) ? [each.value.conditions.host_name_condition] : []
      content {
        operator         = host_name_condition.value.operator
        negate_condition = host_name_condition.value.negate_condition
        match_values     = host_name_condition.value.match_values
        transforms       = host_name_condition.value.transforms
      }
    }
    dynamic "server_port_condition" {
      for_each = can(each.value.conditions.server_port_condition) ? [each.value.conditions.server_port_condition] : []
      content {
        operator         = server_port_condition.value.operator
        negate_condition = server_port_condition.value.negate_condition
        match_values     = server_port_condition.value.match_values
      }
    }
    dynamic "ssl_protocol_condition" {
      for_each = can(each.value.conditions.ssl_protocol_condition) ? [each.value.conditions.ssl_protocol_condition] : []
      content {
        operator         = ssl_protocol_condition.value.operator
        negate_condition = ssl_protocol_condition.value.negate_condition
        match_values     = ssl_protocol_condition.value.match_values
      }
    }
  }

  depends_on = [
    azurerm_cdn_frontdoor_origin_group.main,
    azurerm_cdn_frontdoor_origin.main
  ]
}
