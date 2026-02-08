locals {
  http_errors_section_name = "managed_http_errors_section"
}

resource "haproxy-dataplane_http_errors_section" "managed" {
  name = local.http_errors_section_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "http_errors_section_id" {
  value = haproxy-dataplane_http_errors_section.managed.id
}
