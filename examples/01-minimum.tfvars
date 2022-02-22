nebula_config_output_dir = ".output/nebula"
nebula_mesh = {
  ca = {
    name         = "awesome"
    instance_ids = ["1"]
  }
  nodes = [
    {
      name = "ligthouse"
      ip   = "192.168.127.1/24"

      am_lighthouse = true
      addresses = [
        { host = "180.1.1.2" }
      ]
    },
    {
      name = "node1"
      ip   = "192.168.127.2/24"
    }
  ]
}
