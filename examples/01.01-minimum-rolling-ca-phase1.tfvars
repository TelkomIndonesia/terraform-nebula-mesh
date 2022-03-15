config_output_dir = ".output/nebula"
mesh = {
  ca = {
    name         = "awesome"
    instance_ids = ["", "1"]
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
