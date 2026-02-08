locals {
  backend_http_check_name = "managed_backend_http_check"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

resource "haproxy-dataplane_backend_http_check" "managed" {
  parent_name = var.parent_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "backend_http_check_id" {
  value = haproxy-dataplane_backend_http_check.managed.id
}
