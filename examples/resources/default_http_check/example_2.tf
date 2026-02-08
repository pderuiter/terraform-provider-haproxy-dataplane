locals {
  default_http_check_name = "managed_default_http_check"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

resource "haproxy-dataplane_default_http_check" "managed" {
  parent_name = var.parent_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "default_http_check_id" {
  value = haproxy-dataplane_default_http_check.managed.id
}
