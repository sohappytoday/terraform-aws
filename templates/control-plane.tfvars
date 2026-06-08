instance_type    = "t3.micro"
instance_name    = "control-plane"
root_volume_size = 20
root_volume_type = "gp3"
key_pair_name    = "terraform-key"
public_key_path  = "/home/ubuntu/.ssh/terraform-key.pub"
ssh_allowed_cidr =  "43.203.224.71/32"

ingress_rules = [
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
  },
  {
    description = "Custom 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
]
