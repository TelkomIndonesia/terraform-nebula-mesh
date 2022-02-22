variable "nebula_config_output_dir" {
  type        = string
  default     = ""
  description = "Directory to store generated configuration file. If empty then no configuration file is created"
}

variable "nebula_mesh" {
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
      listen = optional(object({
        host = string
        port = number
      }))
      addresses = optional(list(object({
        host = string
        port = optional(number)
      })))
    }))
  })
  description = "Membership data of nebula network"

  validation {
    condition     = length(var.nebula_mesh.ca.instance_ids) > 0 && join("|", var.nebula_mesh.ca.instance_ids) == join("|", distinct(compact(var.nebula_mesh.ca.instance_ids)))
    error_message = "The `ca.instance_ids` must contains at least 1 item. It should contains arbritrary unique string that will be associated to each generated CA. The public certificate of all CAs will be added to `pki.ca` configuration object, but only CA referenced by the first ID will be used to sign certificates for all nodes."

  }
}
