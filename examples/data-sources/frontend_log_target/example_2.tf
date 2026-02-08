locals {
  frontend_log_target_lookup_name = "existing_frontend_log_target"
}

data "haproxy-dataplane_frontend_log_target" "selected" {
}

output "frontend_log_target_id" {
  value = data.haproxy-dataplane_frontend_log_target.selected.id
}
