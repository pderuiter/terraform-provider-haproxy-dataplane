locals {
  frontend_name = "managed_frontend"
}

resource "haproxy-dataplane_frontend" "managed" {
  name = local.frontend_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "frontend_id" {
  value = haproxy-dataplane_frontend.managed.id
}
