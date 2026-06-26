public_key_path      = "/home/ubuntu/.ssh/terraform-key.pub"
worker_key_pair_name = "terraform-key"

worker_nodes = {
  "worker-1" = {
    # instance_type    = "t3.medium"
    instance_type    = "c7i-flex.large"
    instance_name    = "worker-node-1"
    root_volume_size = 30
    root_volume_type = "gp3"
  }
  "worker-2" = {
    # instance_type    = "t3.medium"
    instance_type    = "c7i-flex.large"
    instance_name    = "worker-node-2"
    root_volume_size = 30
    root_volume_type = "gp3"
  }
}
