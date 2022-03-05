config_output_dir = ".output/nebula"
mesh = {
  ca = {
    name         = "awesome"
    instance_ids = ["2"]
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
