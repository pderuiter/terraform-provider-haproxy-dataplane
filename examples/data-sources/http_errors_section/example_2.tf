locals {
  http_errors_section_lookup_name = "existing_http_errors_section"
}

data "haproxy-dataplane_http_errors_section" "selected" {
}

output "http_errors_section_id" {
  value = data.haproxy-dataplane_http_errors_section.selected.id
}
