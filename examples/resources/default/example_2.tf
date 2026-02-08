locals {
  default_name = "managed_default"
}

resource "haproxy-dataplane_default" "managed" {
  name = local.default_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "default_id" {
  value = haproxy-dataplane_default.managed.id
}
