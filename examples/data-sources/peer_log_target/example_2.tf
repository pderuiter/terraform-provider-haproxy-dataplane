locals {
  peer_log_target_lookup_name = "existing_peer_log_target"
}

data "haproxy-dataplane_peer_log_target" "selected" {
}

output "peer_log_target_id" {
  value = data.haproxy-dataplane_peer_log_target.selected.id
}
