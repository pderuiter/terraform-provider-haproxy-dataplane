locals {
  nameserver_lookup_name = "existing_nameserver"
}

variable "resolver" {
  type = string
}

data "haproxy-dataplane_nameserver" "selected" {
  resolver = var.resolver
}

output "nameserver_id" {
  value = data.haproxy-dataplane_nameserver.selected.id
}
