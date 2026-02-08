locals {
  acme_name = "managed_acme"
}

resource "haproxy-dataplane_acme" "managed" {
  name = local.acme_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "acme_id" {
  value = haproxy-dataplane_acme.managed.id
}
