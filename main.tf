
resource "nebula_ca" "default" {
  for_each = toset(var.mesh.ca.instance_ids)
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
  ])) > 0
}


resource "nebula_certificate" "node" {
  for_each = { for node in var.mesh.nodes : node.name => node }

  ip   = each.value.ip
  name = each.value.name

  groups = compact(distinct((
    try(each.value.lighthouse.am_lighthouse, false) == true ?
    try(coalesce(each.value.groups), []) :
    concat(try(coalesce(each.value.groups), []), [var.default_non_lighthouse_group])
  )))
  public_key             = each.value.public_key
  duration               = each.value.duration
  early_renewal_duration = each.value.early_renewal_duration

  ca_cert = nebula_ca.default[var.mesh.ca.instance_ids[0]].cert
  ca_key  = nebula_ca.default[var.mesh.ca.instance_ids[0]].key
}

locals {
  nebula_node_configs = { for node in var.mesh.nodes :
    node.name => {
      pki = merge(
        {
          ca   = join("", concat([for ca in nebula_ca.default : ca.cert], try(node.pki.additional_ca, [])))
          cert = nebula_certificate.node[node.name].cert
          key  = nebula_certificate.node[node.name].key
        },
        { for k, v in try(coalesce(node.pki), {}) : k => v if k != "additional_ca" && v != null }
      )
      static_host_map = {
        for tnode in var.mesh.nodes :
        split("/", tnode.ip)[0] => [
          for address in tnode.static_addresses :
          "${address.host}:${try(coalesce(address.port, tnode.listen.port), 4242)}"
        ]
        if tnode.static_addresses != null
      }
      lighthouse = merge(
        {
          hosts = [
            for tnode in var.mesh.nodes : split("/", tnode.ip)[0]
            if try(tnode.lighthouse.am_lighthouse, false) == true && try(node.lighthouse.am_lighthouse, false) != true
          ]
          local_allow_list = {
            interfaces = {
              "docker*" = false
              "br*"     = false
              "veth*"   = false
            }
          }
        },
        { for k, v in try(coalesce(node.lighthouse), {}) : k => v if v != null }
      )
      listen = merge(
        {
          port = try(node.lighthouse.am_lighthouse, false) == true ? 4242 : 0
        },
        { for k, v in try(coalesce(node.listen), {}) : k => v if v != null }
      )
      punchy = try(coalesce(node.punchy), {
        punch   = true
        respond = true
        delay   = "1s"
      })
      tun = merge(
        {
          disabled = try(node.lighthouse.am_lighthouse, false) == true && try(node.lighthouse.serve_dns, false) != true && try(node.sshd.enabled, false) != true
        },
        { for k, v in try(coalesce(node.tun), {}) : k => v if v != null }
      )
      firewall = {
        conntrack = try(node.firewall.conntrack, null)
        inbound = try(
          [for rule in node.firewall.inbound : {
            for k, v in rule : k => v if v != null
          }],
          local.is_firewall_defined ? null : [{
            proto = "any", port = "any",
            group = coalesce(var.default_non_lighthouse_group, "any")
          }]
        )
        outbound = try(
          [for rule in node.firewall.outbound : {
            for k, v in rule : k => v if v != null
          }],
          local.is_firewall_defined ? null : [{
            proto = "any", port = "any", host = "any"
          }]
        )
      }

      cipher           = try(node.cipher, null)
      preferred_ranges = try(node.preferred_ranges, null)
      sshd             = { for k, v in try(coalesce(node.sshd), {}) : k => v if v != null }
      handshakes       = { for k, v in try(coalesce(node.handshakes), {}) : k => v if v != null }
      logging          = { for k, v in try(coalesce(node.logging), {}) : k => v if v != null }
      stats            = { for k, v in try(coalesce(node.stats), {}) : k => v if v != null }
    }
  }
}

resource "local_file" "nebula_node_config" {
  for_each = { for k, v in local.nebula_node_configs : k => v if var.config_output_dir != "" }

  filename = "${var.config_output_dir}/${each.key}/nebula.yml"
  content  = yamlencode(each.value)
}

resource "local_file" "nebula_ca" {
  for_each = {
    for node in var.mesh.nodes : node.name => node
    if var.config_output_dir != "" && node.public_key != null
  }
  filename = "${var.config_output_dir}/${each.key}/ca.cert"
  content  = nebula_certificate.node[each.key].ca_cert
}

resource "local_file" "nebula_node_cert" {
  for_each = {
    for node in var.mesh.nodes : node.name => node
    if var.config_output_dir != "" && node.public_key != null
  }
  filename = "${var.config_output_dir}/${each.key}/nebula.cert"
  content  = nebula_certificate.node[each.key].cert
}
