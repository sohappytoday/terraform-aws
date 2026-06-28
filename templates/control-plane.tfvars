ssh_user = "kgeo6"

# Private Subnet으로 이동 후 SSM으로만 접근 → SSH inbound 제거
control_plane_ssh_allowed_cidr = []

control_plane_nodes = {
  "master-1" = {
    instance_type    = "c7i-flex.large"
    instance_name    = "control-plane-1"
    root_volume_size = 20
    root_volume_type = "gp3"
  }
}
