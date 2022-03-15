# Terraform Modules to Manage Nebula Network Membership

An opiniated but overridable [Nebula](https://github.com/slackhq/nebula) configuration generator for managing nodes membership using [terraform](https://github.com/hashicorp/terraform). See [examples](./examples/) for input variable reference.

## Example

```hcl
module "nebula_mesh" {
    source                   = "TelkomIndonesia/mesh/nebula"
  
    config_output_dir = ".output/nebula"
    mesh = {
        ca = {
            name = "awesome"
        }
        nodes = [
            {
                name = "lighthouse"
                ip   = "192.168.127.1/24"
                static_addresses = [
                    { host = "180.1.1.2" }
                ]

                lighthouse = {
                    am_lighthouse = true
                }
            },
            {
                name = "node1"
                ip   = "192.168.127.2/24"
            },
            {
                name       = "phone1"
                ip         = "192.168.127.3/24"
                public_key = <<-EOF
                    -----BEGIN NEBULA X25519 PUBLIC KEY-----
                    1f/iyVqtpEXsBSvvihF6MPHbEqXMsy0+bfWurXtu9HY=
                    -----END NEBULA X25519 PUBLIC KEY-----
                EOF
            }
        ]
    }
}
```
