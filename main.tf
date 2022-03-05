
resource "nebula_ca" "default" {
  for_each = toset(var.nebula_mesh.ca.instance_ids)
  name     = var.nebula_mesh.ca.name

  groups                 = var.nebula_mesh.ca.groups
  ips                    = var.nebula_mesh.ca.ips
  subnets                = var.nebula_mesh.ca.subnets
  duration               = var.nebula_mesh.ca.duration
  early_renewal_duration = var.nebula_mesh.ca.early_renewal_duration
}

locals {
  default_non_lighthouse_group = "_nodes_"
  is_firewall_defined = length(flatten([
    for node in var.nebula_mesh.nodes :
    concat(
      lookup(node.firewall, "inbound", null) == null ? [] : node.firewall.inbound,
      lookup(node.firewall, "outbound", null) == null ? [] : node.firewall.outbound
    )
    if lookup(node, "firewall", null) != null
  ])) > 0
}


resource "nebula_certificate" "node" {
  for_each = { for node in var.nebula_mesh.nodes : node.name => node }

  ip   = each.value.ip
  name = each.value.name

  groups = (
    lookup(each.value, "am_lighthouse", null) == true ?
    each.value.groups :
    distinct(concat(each.value.groups != null ? each.value.groups : [], [local.default_non_lighthouse_group]))
  )
  public_key             = each.value.public_key
  duration               = each.value.duration
  early_renewal_duration = each.value.early_renewal_duration

  ca_cert = nebula_ca.default[var.nebula_mesh.ca.instance_ids[0]].cert
  ca_key  = nebula_ca.default[var.nebula_mesh.ca.instance_ids[0]].key
}

locals {
  nebula_node_configs = { for node in var.nebula_mesh.nodes :
    node.name => {
      pki = {
        ca   = join("", [for ca in nebula_ca.default : ca.cert])
        cert = nebula_certificate.node[node.name].cert
        key  = nebula_certificate.node[node.name].key
        blocklist = [
          for tnode in var.nebula_mesh.nodes :
          nebula_certificate.node[tnode.name].fingerprint
          if lookup(tnode, "blocked", false) == true
        ]
      }
      static_host_map = {
        for tnode in var.nebula_mesh.nodes :
        split("/", tnode.ip)[0] => [
          for address in tnode.addresses : "${address.host}:${
            lookup(address, "port", null) != null ? address.port : (
              tnode.listen != null ? tnode.listen.port : (
                lookup(tnode, "am_lighthouse", false) == true ? 4242 : 0
              )
            )
          }"
        ]
        if tnode.addresses != null
      }
      lighthouse = {
        am_lighthouse = lookup(node, "am_lighthouse", false) == true
        serve_dns     = lookup(node, "serve_dns", false)
        dns = lookup(node, "serve_dns", false) != true ? null : {
          host = "0.0.0.0"
          port = 53
        }
        hosts = [
          for tnode in var.nebula_mesh.nodes : split("/", tnode.ip)[0]
          if lookup(tnode, "am_lighthouse", false) == true && lookup(node, "am_lighthouse", false) != true
        ]
        local_allow_list = {
          interfaces = {
            "docker*" = false
            "br-*"    = false
            "veth*"   = false
          }
        }
      }
      listen = {
        host = node.listen != null ? node.listen.host : "0.0.0.0"
        port = node.listen != null ? node.listen.port : (
          lookup(node, "am_lighthouse", false) == true ? 4242 : 0
        )
      }
      punchy = {
        punch   = true
        respond = true
        delay   = "1s"
      }
      tun = {
        disabled             = lookup(node, "am_lighthouse", false) == true && lookup(node, "serve_dns", false) != true
        drop_local_broadcast = false
        drop_multicast       = false
      }
      firewall = {
        inbound = try([
          for rule in node.firewall.inbound : {
            for k, v in rule : k => v if v != null
          }
        ], local.is_firewall_defined ? null : [{ proto = "any", port = "any", group = local.default_non_lighthouse_group, }])
        outbound = try([
          for rule in node.firewall.outbound : {
            for k, v in rule : k => v if v != null
          }
        ], local.is_firewall_defined ? null : [{ proto = "any", port = "any", host = "any" }])
      }
    }
  }
}

resource "local_file" "nebula_node_config" {
  for_each = { for k, v in local.nebula_node_configs : k => v if var.nebula_config_output_dir != "" }

  filename = "${var.nebula_config_output_dir}/${each.key}/nebula.yml"
  content  = yamlencode(each.value)
}

resource "local_file" "nebula_ca" {
  for_each = {
    for node in var.nebula_mesh.nodes : node.name => node
    if var.nebula_config_output_dir != "" && node.public_key != null
  }
  filename = "${var.nebula_config_output_dir}/${each.key}/ca.cert"
  content  = nebula_certificate.node[each.key].ca_cert
}

resource "local_file" "nebula_node_cert" {
  for_each = {
    for node in var.nebula_mesh.nodes : node.name => node
    if var.nebula_config_output_dir != "" && node.public_key != null
  }
  filename = "${var.nebula_config_output_dir}/${each.key}/nebula.cert"
  content  = nebula_certificate.node[each.key].cert
}
