locals {
  log_profile_name = "managed_log_profile"
}

resource "haproxy-dataplane_log_profile" "managed" {
  name = local.log_profile_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "log_profile_id" {
  value = haproxy-dataplane_log_profile.managed.id
}
