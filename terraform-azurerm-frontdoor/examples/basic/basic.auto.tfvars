resource_group_name = "terraform-learning"
frontdoor_profile = {
  name     = "terraform-cdn-profile"
  sku_name = "Standard_AzureFrontDoor"
  tags = {
    environment = "Production"
  }
}

origin_groups = {
  mymobileapp-usa = {}
  mymobileapp-uk  = {}
}

origin_list = {
  newyork = {
    host_name         = "ny.mymobileapp.us"
    origin_group_name = "mymobileapp-usa"
    enabled           = false
  }
  california = {
    host_name         = "ca.mymobileapp.us"
    origin_group_name = "mymobileapp-usa"
  }
  london = {
    host_name         = "london.mymobileapp.uk"
    origin_group_name = "mymobileapp-uk"
    http_port         = 8080
    https_port        = 8433
  }
}

dns_zones = ["mymobileapp.us", "mymobileapp.uk"]

custom_domains = [
  {
    dns_zone = "mymobileapp.us"
    domains  = ["ca", "ny"]
    route    = "us-routes"
  },
  {
    dns_zone = "mymobileapp.uk"
    domains  = ["london"]
    route    = "uk-routes"
  }
]

endpoints = ["us-endpoint", "uk-endpoint"]

routes = {
  us-routes = {
    endpoint               = "us-endpoint"
    origin_group           = "mymobileapp-usa"
    origin_list            = ["newyork", "california"]
    link_to_default_domain = true
    rule_sets              = ["usrules"]
  }
  uk-routes = {
    endpoint               = "uk-endpoint"
    origin_group           = "mymobileapp-uk"
    origin_list            = ["london"]
    link_to_default_domain = true
    rule_sets              = []
  }
}

rule_sets = {
  usrules = {
    rules = {
      californiarule = {
        order             = 1
        behavior_on_match = "Continue"
        origin_group      = "mymobileapp-usa"
        actions = {
          route_configuration_override_action = {
            forwarding_protocol     = "HttpOnly"
            compression_enabled     = false
            query_string_parameters = ["home"]
          }
        }
        conditions = {
          remote_address_condition = {
            operator     = "IPMatch"
            match_values = ["10.0.0.0/24"]
          }
          request_method_condition = {
            operator         = "Equal"
            negate_condition = false
            match_values     = ["DELETE"]
          }
        }
      }
      elpaso = {
        order             = 1
        behavior_on_match = "Continue"
        origin_group      = "mymobileapp-usa"
        actions = {
          route_configuration_override_action = {
            forwarding_protocol     = "HttpOnly"
            compression_enabled     = false
            query_string_parameters = ["home"]
          }
        }
        conditions = {
          remote_address_condition = {
            operator     = "IPMatch"
            match_values = ["10.0.0.0/24"]
          }
          request_method_condition = {
            operator         = "Equal"
            negate_condition = false
            match_values     = ["DELETE"]
          }
        }
      }
    }
  }
}