locals {
  global_log_target_lookup_name = "existing_global_log_target"
}

data "haproxy-dataplane_global_log_target" "selected" {
}

output "global_log_target_id" {
  value = data.haproxy-dataplane_global_log_target.selected.id
}
