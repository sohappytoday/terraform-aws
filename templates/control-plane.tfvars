ssh_user = "kgeo6"

# 잠시 열어둘것
control_plane_ssh_allowed_cidr = ["0.0.0.0/0"]

control_plane_nodes = {
  "master-1" = {
    instance_type    = "c7i-flex.large"
    instance_name    = "control-plane-1"
    root_volume_size = 20
    root_volume_type = "gp3"
  }
}
