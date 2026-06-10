module "control_plane" {
  source = "./modules/lightsail"

  instance_name     = var.lightsail_instance_name
  availability_zone = var.lightsail_availability_zone
  blueprint_id      = var.lightsail_blueprint_id
  bundle_id         = var.lightsail_bundle_id
  key_pair_name     = var.lightsail_key_pair_name
  public_key_path   = var.public_key_path
  ip_address_type   = var.lightsail_ip_address_type
  port_rules        = var.lightsail_port_rules
}

resource "aws_key_pair" "worker_node" {
  key_name   = var.worker_key_pair_name
  public_key = file(var.public_key_path)
}

module "worker_node" {
  for_each = var.worker_nodes
  source   = "./modules/ec2"

  instance_type    = each.value.instance_type
  instance_name    = each.value.instance_name
  root_volume_size = each.value.root_volume_size
  root_volume_type = each.value.root_volume_type
  key_pair_name    = aws_key_pair.worker_node.key_name
  ssh_allowed_cidr = var.ssh_allowed_cidr
  ingress_rules    = var.ingress_rules
}
