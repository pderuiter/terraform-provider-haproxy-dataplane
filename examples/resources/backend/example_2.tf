locals {
  backend_name = "managed_backend"
}

resource "haproxy-dataplane_backend" "managed" {
  name = local.backend_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "backend_id" {
  value = haproxy-dataplane_backend.managed.id
}
