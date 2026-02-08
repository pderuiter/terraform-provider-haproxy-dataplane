locals {
  log_forward_dgram_bind_lookup_name = "existing_log_forward_dgram_bind"
}

data "haproxy-dataplane_log_forward_dgram_bind" "selected" {
}

output "log_forward_dgram_bind_id" {
  value = data.haproxy-dataplane_log_forward_dgram_bind.selected.id
}
