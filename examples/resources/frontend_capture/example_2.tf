locals {
  frontend_capture_name = "managed_frontend_capture"
}

variable "parent_name" {
  description = "Parent object name, for example a frontend or backend name."
  type        = string
}

resource "haproxy-dataplane_frontend_capture" "managed" {
  parent_name = var.parent_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "frontend_capture_id" {
  value = haproxy-dataplane_frontend_capture.managed.id
}
