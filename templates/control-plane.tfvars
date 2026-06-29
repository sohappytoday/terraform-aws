ssh_user = "ubuntu"

# Private Subnet으로 이동 후 SSM으로만 접근 → SSH inbound 제거
control_plane_ssh_allowed_cidr = []

# HA: control-plane 3대 (etcd 쿼럼). 내부 NLB가 6443 단일 엔드포인트로 묶는다.
control_plane_nodes = {
  "master-1" = {
    instance_type    = "t3.small"
    instance_name    = "control-plane-1"
    root_volume_size = 20
    root_volume_type = "gp3"
  }
  "master-2" = {
    instance_type    = "t3.small"
    instance_name    = "control-plane-2"
    root_volume_size = 20
    root_volume_type = "gp3"
  }
  "master-3" = {
    instance_type    = "t3.small"
    instance_name    = "control-plane-3"
    root_volume_size = 20
    root_volume_type = "gp3"
  }
}
