locals {
  nameserver_name = "managed_nameserver"
}

variable "resolver" {
  type = string
}

resource "haproxy-dataplane_nameserver" "managed" {
  name     = local.nameserver_name
  resolver = var.resolver

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "nameserver_id" {
  value = haproxy-dataplane_nameserver.managed.id
}
