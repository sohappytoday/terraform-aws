control_plane_instance_name    = "control-plane"
control_plane_instance_type    = "t3.small"
control_plane_root_volume_size = 20
control_plane_root_volume_type = "gp3"
control_plane_ssh_allowed_cidr = ["121.134.174.157/32"]

control_plane_ingress_rules = [
  {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  },
  {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
]
