locals {
  frontend_capture_lookup_name = "existing_frontend_capture"
}

data "haproxy-dataplane_frontend_capture" "selected" {
}

output "frontend_capture_id" {
  value = data.haproxy-dataplane_frontend_capture.selected.id
}
