ssh_user = "ubuntu"

control_plane_ssh_allowed_cidr = ["121.134.174.157/32", "3.39.227.252/32"]

control_plane_nodes = {
  "master-1" = {
    instance_type    = "c7i-flex.large"
    instance_name    = "control-plane-1"
    root_volume_size = 20
    root_volume_type = "gp3"
  }
}
