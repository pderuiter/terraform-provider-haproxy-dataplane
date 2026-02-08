locals {
  crt_load_name = "managed_crt_load"
}

variable "certificate" {
  type = string
}

variable "crt_store" {
  type = string
}

resource "haproxy-dataplane_crt_load" "managed" {
  certificate = var.certificate
  crt_store   = var.crt_store

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "crt_load_id" {
  value = haproxy-dataplane_crt_load.managed.id
}
