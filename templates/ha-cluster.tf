module "control_plane" {
  source = "./modules/lightsail"

  instance_name     = var.lightsail_instance_name
  availability_zone = var.lightsail_availability_zone
  blueprint_id      = var.lightsail_blueprint_id
  bundle_id         = var.lightsail_bundle_id
  key_pair_name     = var.key_pair_name
  public_key_path   = var.public_key_path
  ip_address_type   = var.lightsail_ip_address_type
  port_rules        = var.lightsail_port_rules
}

module "worker_node" {
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
