locals {
  log_forward_name = "managed_log_forward"
}

resource "haproxy-dataplane_log_forward" "managed" {
  name = local.log_forward_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "log_forward_id" {
  value = haproxy-dataplane_log_forward.managed.id
}
