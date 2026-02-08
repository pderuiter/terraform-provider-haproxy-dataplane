locals {
  default_log_target_lookup_name = "existing_default_log_target"
}

data "haproxy-dataplane_default_log_target" "selected" {
}

output "default_log_target_id" {
  value = data.haproxy-dataplane_default_log_target.selected.id
}
