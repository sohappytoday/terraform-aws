module "control_plane" {
  source = "./modules/ec2"

  instance_type    = var.instance_type
  instance_name    = var.instance_name
  root_volume_size = var.root_volume_size
  root_volume_type = var.root_volume_type
  key_pair_name    = var.key_pair_name
  public_key_path  = var.public_key_path
  ssh_allowed_cidr = var.ssh_allowed_cidr
  ingress_rules    = var.ingress_rules
}
