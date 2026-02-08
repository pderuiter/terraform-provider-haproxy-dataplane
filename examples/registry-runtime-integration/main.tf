terraform {
  required_version = ">= 1.5"

  required_providers {
    haproxy-dataplane = {
      source  = "pderuiter/haproxy-dataplane"
      version = "= 0.1.7"
    }
  }
}

variable "haproxy_admin_password" {
  type      = string
  sensitive = true
}

variable "name_suffix" {
  type = string
}

provider "haproxy-dataplane" {
  endpoint = "http://localhost:5555"
  username = "admin"
  password = var.haproxy_admin_password
  api_path = "/v3"
}

resource "haproxy-dataplane_runtime_backend_server" "runtime_added" {
  parent_name = "be_http"
  name        = "runtime-${var.name_suffix}"
  spec = {
    address = "echo"
    port    = 5678
    check   = "enabled"
  }
}
