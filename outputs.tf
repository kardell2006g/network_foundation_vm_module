output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_name" {
  value = var.vpc_name
}

output "subnet_ids_by_network" {
  description = "Subnet IDs grouped by network name (Web, App, Bastion)."
  value = {
    for network in keys(var.networks) :
    network => [for k, s in local.subnets : aws_subnet.this[k].id if s.network == network]
  }
}
