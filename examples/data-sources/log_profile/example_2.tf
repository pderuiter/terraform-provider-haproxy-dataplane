locals {
  log_profile_lookup_name = "existing_log_profile"
}

data "haproxy-dataplane_log_profile" "selected" {
}

output "log_profile_id" {
  value = data.haproxy-dataplane_log_profile.selected.id
}
