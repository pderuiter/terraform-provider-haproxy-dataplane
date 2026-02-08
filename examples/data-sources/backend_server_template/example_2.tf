locals {
  backend_server_template_lookup_name = "existing_backend_server_template"
}

data "haproxy-dataplane_backend_server_template" "selected" {
}

output "backend_server_template_id" {
  value = data.haproxy-dataplane_backend_server_template.selected.id
}
