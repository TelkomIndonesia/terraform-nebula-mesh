
locals {
  ca_instance_ids = try(coalesce(var.mesh.ca.instance_ids), [""])
}

resource "nebula_ca" "default" {
  for_each = toset(local.ca_instance_ids)
  name     = var.mesh.ca.name

  groups                 = var.mesh.ca.groups
  ips                    = var.mesh.ca.ips
  subnets                = var.mesh.ca.subnets
  duration               = var.mesh.ca.duration
  early_renewal_duration = var.mesh.ca.early_renewal_duration
}

locals {
  is_firewall_defined = length(flatten([
    for node in var.mesh.nodes :
    concat(
      try(coalesce(node.firewall.inbound), []),
      try(coalesce(node.firewall.outbound), []),
    )
    if try(coalesce(node.active), true)
  ])) > 0

  nodes = { for node in var.mesh.nodes :
    try(join("-", [node.name, node.instance_id]), node.name) => node
  }
}

resource "nebula_certificate" "node" {
  for_each = local.nodes

  ip   = each.value.ip
  name = each.value.name

  groups = compact(distinct((
    try(each.value.lighthouse.am_lighthouse, false) == true ?
    try(coalesce(each.value.groups), []) :
    concat(try(coalesce(each.value.groups), []), [var.default_non_lighthouse_group])
  )))
  subnets                = each.value.subnets
  public_key             = each.value.public_key
  duration               = each.value.duration
  early_renewal_duration = each.value.early_renewal_duration

  ca_cert = nebula_ca.default[local.ca_instance_ids[0]].cert
  ca_key  = nebula_ca.default[local.ca_instance_ids[0]].key
}

locals {
  nebula_node_configs = { for node_key, node in local.nodes :
    node_key => {
      pki = merge(
        try(coalesce(node.pki), {}),
        {
          ca = join("\n", concat(
            [for ca in nebula_ca.default : ca.cert],
            try(coalesce(node.pki.ca), [])
          ))
          cert = nebula_certificate.node[node_key].cert
          key  = nebula_certificate.node[node_key].key
          blocklist = concat(
            try(coalesce(node.pki.blocklist), []),
            [
              for node_key, cert in nebula_certificate.node :
              cert.fingerprint
              if !try(coalesce(local.nodes[node_key].active), true)
            ]
          )
        }
      )

      static_host_map = {
        for tnode in var.mesh.nodes :
        split("/", tnode.ip)[0] => [
          for address in tnode.static_addresses :
          "${address.host}:${try(coalesce(address.port, tnode.listen.port), 4242)}"
          if address != null
        ]
        if tnode.static_addresses != null && try(coalesce(tnode.active), true)
      }
      lighthouse = merge(
        try(coalesce(node.lighthouse), {}),
        {
          hosts = try(coalesce(node.lighthouse.hosts),
            [
              for tnode in var.mesh.nodes : split("/", tnode.ip)[0]
              if !try(coalesce(node.lighthouse.am_lighthouse), false) && try(coalesce(tnode.lighthouse.am_lighthouse), false) && try(coalesce(tnode.active), true)
            ]
          )
          local_allow_list = try(coalesce(node.lighthouse.local_allow_list),
            {
              interfaces = {
                "docker*" = false
                "br*"     = false
                "veth*"   = false
              }
            }
          )
        }
      )
      listen = merge(
        try(coalesce(node.listen), {}),
        {
          port = try(coalesce(node.listen.port),
            try(coalesce(node.lighthouse.am_lighthouse), false) ? 4242 : 0
          )
        }
      )
      punchy = try(coalesce(node.punchy), {
        punch   = true
        respond = true
        delay   = "1s"
      })
      tun = merge(
        try(coalesce(node.tun), {}),
        {
          disabled = try(coalesce(node.tun.disabled),
            try(coalesce(node.lighthouse.am_lighthouse), false) &&
            !try(coalesce(node.lighthouse.serve_dns), false) &&
            !try(coalesce(node.sshd.enabled), false)
          )
        },
      )
      firewall = {
        conntrack = try(node.firewall.conntrack, null)
        inbound = try(
          coalesce(node.firewall.inbound),
          local.is_firewall_defined ? null : [{
            proto = "any", port = "any",
            group = coalesce(var.default_non_lighthouse_group, "any")
          }]
        )
        outbound = try(
          coalesce(node.firewall.outbound),
          local.is_firewall_defined ? null : [{
            proto = "any", port = "any", host = "any"
          }]
        )
      }

      cipher           = node.cipher
      preferred_ranges = node.preferred_ranges
      sshd             = node.sshd
      handshakes       = node.handshakes
      logging          = node.logging
      stats            = node.stats
    }
    if try(coalesce(node.active), true)
  }
}

resource "local_file" "nebula_node_config" {
  for_each = { for k, v in local.nebula_node_configs : k => v if var.config_output_dir != "" }

  filename = "${var.config_output_dir}/${each.key}/nebula.yml"
  content  = replace(yamlencode(each.value), "/\"\\b\\w+\":\\s+null(\\n|$)/", "\n")
}

resource "local_file" "nebula_ca" {
  for_each = {
    for node_key, cert in nebula_certificate.node : node_key => cert
    if var.config_output_dir != "" && local.nodes[node_key].public_key != null
  }
  filename = "${var.config_output_dir}/${each.key}/ca.cert"
  content  = each.value.ca_cert
}

resource "local_file" "nebula_node_cert" {
  for_each = {
    for node_key, cert in nebula_certificate.node : node_key => cert
    if var.config_output_dir != "" && local.nodes[node_key].public_key != null
  }
  filename = "${var.config_output_dir}/${each.key}/nebula.cert"
  content  = each.value.cert
}
