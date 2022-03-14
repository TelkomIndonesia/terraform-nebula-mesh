variable "config_output_dir" {
  type        = string
  default     = ""
  description = "Directory to store generated configuration file. If empty then no configuration file is created."
}

variable "default_non_lighthouse_group" {
  type        = string
  default     = "_nodes_"
  description = "default group to be added to all nodes that are not lighthouse. Set empty to prevent addition of default group"
}

variable "mesh" {
  type = object({
    ca = object({
      instance_ids = optional(list(string))

      name                   = string
      groups                 = optional(list(string))
      ips                    = optional(list(string))
      subnets                = optional(list(string))
      duration               = optional(string)
      early_renewal_duration = optional(string)
    })

    nodes = list(object({
      instance_id = optional(string)
      active      = optional(bool)

      name                   = string
      groups                 = optional(list(string))
      ip                     = string
      subnets                = optional(list(string))
      public_key             = optional(string)
      duration               = optional(string)
      early_renewal_duration = optional(string)

      static_addresses = optional(list(object({
        host = string
        port = optional(number)
      })))

      pki = optional(object({
        blocklist          = optional(list(string))
        disconnect_invalid = optional(bool)
        additional_ca      = optional(list(string))
      }))

      lighthouse = optional(object({
        am_lighthouse = optional(bool)
        serve_dns     = optional(bool)
        dns = optional(object({
          host = optional(string)
          port = optional(number)
        }))
        interval          = optional(number)
        remote_allow_list = optional(map(bool))
        local_allow_list  = optional(map(any))
      }))

      listen = optional(object({
        host         = optional(string)
        port         = optional(number)
        batch        = optional(number)
        read_buffer  = optional(number)
        write_buffer = optional(number)
      }))

      punchy = optional(object({
        punch   = optional(bool)
        respond = optional(bool)
        delay   = optional(string)
      }))

      cipher           = optional(string)
      preferred_ranges = optional(list(string))

      sshd = optional(object({
        enabled  = bool
        listen   = string
        host_key = string
        authorized_users = optional(list(object({
          user = string
          keys = list(string)
        })))
      }))

      tun = optional(object({
        disabled             = optional(bool)
        dev                  = optional(string)
        drop_local_broadcast = optional(bool)
        drop_multicast       = optional(bool)
        tx_queue             = optional(number)
        mtu                  = optional(number)
        routes = optional(list(object({
          mtu   = number
          route = string
        })))
        unsafe_routes = optional(list(object({
          route  = string
          via    = string
          mtu    = optional(number)
          metric = optional(number)
        })))
      }))

      handshakes = optional(object({
        try_interval   = optional(string)
        retries        = optional(number)
        trigger_buffer = optional(number)
      }))

      logging = optional(object({
        level             = optional(string)
        format            = optional(string)
        disable_timestamp = optional(bool)
        timestamp_format  = optional(string)
      }))

      stats = optional(object({
        type = string

        prefix   = optional(string)
        protocol = optional(string)
        host     = optional(string)
        interval = optional(string)

        listen    = optional(string)
        path      = optional(string)
        namespace = optional(string)
        subsystem = optional(string)
        interval  = optional(string)

        message_metrics    = optional(bool)
        lighthouse_metrics = optional(bool)
      }))

      firewall = optional(object({
        conntrack = optional(object({
          tcp_timeout     = optional(string)
          udp_timeout     = optional(string)
          default_timeout = optional(string)
          max_connections = optional(number)
        }))
        inbound = optional(list(object({
          port    = string
          proto   = string
          ca_sha  = optional(string)
          ca_name = optional(string)
          host    = optional(string)
          group   = optional(string)
          groups  = optional(list(string))
          cidr    = optional(string)
        })))
        outbound = optional(list(object({
          port    = string
          proto   = string
          ca_sha  = optional(string)
          ca_name = optional(string)
          host    = optional(string)
          group   = optional(string)
          groups  = optional(list(string))
          cidr    = optional(string)
        })))
      }))
    }))
  })
  description = "Membership data of nebula network"

  validation {
    condition     = join("|", try(coalesce(var.mesh.ca.instance_ids), [])) == join("|", distinct(try(coalesce(var.mesh.ca.instance_ids), [])))
    error_message = "The `ca.instance_ids` must contains arbritrary unique string that will be associated to each generated CA. The public certificate of all CAs will be added to `pki.ca` configuration object, but only CA referenced by the first ID will be used to sign certificates for all nodes."
  }
  validation {
    condition     = length([for node in var.mesh.nodes : node if try(coalesce(node.active), true)]) == length(distinct([for nodes in [for node in var.mesh.nodes : node if try(coalesce(node.active), true)] : split("/", nodes.ip)[0]]))
    error_message = "The `nodes[*].ip` should be unique on each node."
  }
  validation {
    condition = length([
      for v in compact(flatten([
        for node in [for node in var.mesh.nodes : node if try(coalesce(node.active), true)] :
        concat(
          keys(try(coalesce(node.lighthouse.remote_allow_list), {})),
          [for k, v in try(coalesce(node.lighthouse.local_allow_list), {}) : k if k != "interfaces"],
          try(coalesce(node.preferred_ranges), []),
          [for route in try(coalesce(node.tun.routes), []) : try(coalesce(route.route), null)],
          [for route in try(coalesce(node.tun.unsafe_routes), []) : try(coalesce(route.route), null)],
          [for rule in try(coalesce(node.firewall.inbound), []) : try(coalesce(rule.cidr), null)],
          [for rule in try(coalesce(node.firewall.outbound), []) : try(coalesce(rule.cidr), null)],
        )
      ])) :
      v if try(cidrhost(v, 0), "") == ""
    ]) == 0
    error_message = "Expected `lighthouse.remote_allow_list`, `llighthouse.ocal_allow_list`, `preferred_ranges`, `tun.routes`, `tun.unsafe_routes`, `firewall.inbound` and `firewall.outbound` to contain a valid CIDR."
  }
  validation {
    condition = length([
      for rule in flatten([
        for node in [for node in var.mesh.nodes : node if try(coalesce(node.active), true)] :
        concat(
          try(coalesce(node.firewall.inbound), []),
          try(coalesce(node.firewall.outbound), []),
        )
      ]) :
      rule
      if lookup(rule, "ca_name", null) == null &&
      lookup(rule, "host", null) == null &&
      lookup(rule, "group", null) == null &&
      lookup(rule, "cidr", null) == null &&
      try(length(lookup(rule, "groups", [])), 0) == 0
    ]) == 0
    error_message = "Invalid firewall definition. at least one of `host`, `group`, `groups`, `cidr`, or `ca_name` must be provided."
  }
}
