control_plane_key_pair_name     = "terraform-key"
control_plane_instance_name     = "control-plane"
control_plane_availability_zone = "ap-northeast-2a"

control_plane_port_rules = [
  {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidrs     = ["121.134.174.157/32"]
  },
  {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
    cidrs     = ["0.0.0.0/0"]
  },
  {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
    cidrs     = ["0.0.0.0/0"]
  }
]
