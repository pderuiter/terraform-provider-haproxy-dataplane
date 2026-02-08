locals {
  crt_load_lookup_name = "existing_crt_load"
}

variable "crt_store" {
  type = string
}

data "haproxy-dataplane_crt_load" "selected" {
  crt_store = var.crt_store
}

output "crt_load_id" {
  value = data.haproxy-dataplane_crt_load.selected.id
}
