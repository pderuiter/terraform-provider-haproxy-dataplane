locals {
  log_forward_lookup_name = "existing_log_forward"
}

data "haproxy-dataplane_log_forward" "selected" {
}

output "log_forward_id" {
  value = data.haproxy-dataplane_log_forward.selected.id
}
