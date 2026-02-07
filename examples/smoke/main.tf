terraform {
  required_version = ">= 1.5"
  required_providers {
    haproxy-dataplane = {
      source  = "pderuiter/haproxy-dataplane"
      version = "0.1.0"
    }
  }
}

variable "haproxy_admin_password" {
  type      = string
  sensitive = true
}

provider "haproxy-dataplane" {
  endpoint = "http://localhost:5555"
  username = "admin"
  password = var.haproxy_admin_password
  api_path = "/v3"
}

resource "haproxy-dataplane_backend" "smoke" {
  name = "be_smoke"
  spec = {
    mode    = "http"
    balance = "roundrobin"
  }
}

resource "haproxy-dataplane_frontend" "smoke" {
  name = "fe_smoke"
  spec = {
    mode            = "http"
    default_backend = haproxy-dataplane_backend.smoke.name
  }
}

resource "haproxy-dataplane_bind" "smoke" {
  frontend = haproxy-dataplane_frontend.smoke.name
  name     = "smoke"
  spec = {
    address = "*"
    port    = 18080
  }
}

resource "haproxy-dataplane_server" "smoke" {
  backend = haproxy-dataplane_backend.smoke.name
  name    = "s1"
  spec = {
    address = "127.0.0.1"
    port    = 19000
  }
}
