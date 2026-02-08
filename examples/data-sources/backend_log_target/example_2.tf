locals {
  backend_log_target_lookup_name = "existing_backend_log_target"
}

data "haproxy-dataplane_backend_log_target" "selected" {
}

output "backend_log_target_id" {
  value = data.haproxy-dataplane_backend_log_target.selected.id
}
