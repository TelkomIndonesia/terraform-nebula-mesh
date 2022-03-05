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
      name                   = string
      groups                 = optional(list(string))
      ips                    = optional(list(string))
      subnets                = optional(list(string))
      duration               = optional(string)
      early_renewal_duration = optional(string)

      instance_ids = list(string)
    })

    nodes = list(object({
      name                   = string
      groups                 = optional(list(string))
      ip                     = string
      subnets                = optional(list(string))
      public_key             = optional(string)
      duration               = optional(string)
      early_renewal_duration = optional(string)

      am_lighthouse = optional(bool)
      blocked       = optional(bool)
      blocklist     = optional(list(string))
      listen = optional(object({
        host = optional(string)
        port = optional(number)
      }))
      addresses = optional(list(object({
        host = string
        port = optional(number)
      })))
      routes_mtu = optional(list(object({
        mtu   = number
        route = string
      })))
      firewall = optional(object({
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
    condition     = length(var.mesh.ca.instance_ids) > 0 && join("|", var.mesh.ca.instance_ids) == join("|", distinct(compact(var.mesh.ca.instance_ids)))
    error_message = "The `ca.instance_ids` must contains at least 1 item. It should contains arbritrary unique string that will be associated to each generated CA. The public certificate of all CAs will be added to `pki.ca` configuration object, but only CA referenced by the first ID will be used to sign certificates for all nodes."
  }
  validation {
    condition     = length(var.mesh.nodes) == length(distinct([for nodes in var.mesh.nodes : split("/", nodes.ip)[0]]))
    error_message = "The `nodes[*].ip` should be unique on each node."
  }
  validation {
    condition = length([
      for v in try(flatten([
        for node in var.mesh.nodes : node.routes_mtu
      ]), []) :
      v if try(cidrhost(v.route, 0), "") == ""
    ]) == 0
    error_message = "The `nodes[*].routes_mtu[*].route` must be valid CIDR."
  }
  validation {
    condition = length([
      for rule in flatten([
        for node in var.mesh.nodes :
        concat(
          lookup(node.firewall, "inbound", null) == null ? [] : node.firewall.inbound,
          lookup(node.firewall, "outbound", null) == null ? [] : node.firewall.outbound
        )
        if lookup(node, "firewall", null) != null
      ]) :
      rule
      if lookup(rule, "ca_name", null) == null &&
      lookup(rule, "host", null) == null &&
      lookup(rule, "group", null) == null &&
      lookup(rule, "cidr", null) == null &&
      try(length(lookup(rule, "groups", [])), 0) == 0
      ]
    ) == 0
    error_message = "Invalid firewall definition. at least one of `host`, `group`, `groups`, `cidr`, or `ca_name` must be provided."
  }
}
