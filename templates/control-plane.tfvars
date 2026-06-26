ssh_user                       = "ubuntu"
control_plane_instance_name    = "control-plane"
# control_plane_instance_type    = "t3.medium"
control_plane_instance_type    = "c7i-flex.large"
control_plane_root_volume_size = 20
control_plane_root_volume_type = "gp3"
control_plane_ssh_allowed_cidr = ["121.134.174.157/32", "3.39.227.252/32"]
