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

resource "haproxy-dataplane_backend" "main" {
  name = "be_main_${var.name_suffix}"
  spec = {
    mode = "http"
    balance = {
      algorithm = "roundrobin"
    }
  }
}

resource "haproxy-dataplane_backend_server" "main_echo" {
  parent_name = haproxy-dataplane_backend.main.name
  name        = "echo-1-${var.name_suffix}"
  spec = {
    address = "echo"
    port    = 5678
    check   = "enabled"
  }
}

resource "haproxy-dataplane_frontend" "main" {
  name = "fe_main_${var.name_suffix}"
  spec = {
    mode            = "http"
    default_backend = haproxy-dataplane_backend.main.name
  }
}

resource "haproxy-dataplane_frontend_bind" "main" {
  parent_name = haproxy-dataplane_frontend.main.name
  name        = "http"
  spec = {
    address = "*"
    port    = 18081
  }
}

resource "haproxy-dataplane_resolver" "consul" {
  name = "consul_dns_${var.name_suffix}"
  spec = {
    parse_resolv_conf = false
    resolve_retries   = 3
    timeout_resolve   = 1000
    timeout_retry     = 1000
    hold_valid        = 10000
  }
}

resource "haproxy-dataplane_nameserver" "consul" {
  resolver = haproxy-dataplane_resolver.consul.name
  name     = "consul_${var.name_suffix}"
  spec = {
    address = "consul"
    port    = 8600
  }
}

resource "haproxy-dataplane_backend" "sd" {
  name = "be_sd_${var.name_suffix}"
  spec = {
    mode = "http"
    balance = {
      algorithm = "roundrobin"
    }
  }
}

resource "haproxy-dataplane_backend_server" "sd_echo" {
  parent_name = haproxy-dataplane_backend.sd.name
  name        = "sd-echo-${var.name_suffix}"
  spec = {
    address        = "echo.service.consul"
    port           = 5678
    check          = "enabled"
    resolvers      = haproxy-dataplane_resolver.consul.name
    init_addr      = "none"
    resolve_prefer = "ipv4"
  }
}

resource "haproxy-dataplane_frontend" "sd" {
  name = "fe_sd_${var.name_suffix}"
  spec = {
    mode            = "http"
    default_backend = haproxy-dataplane_backend.sd.name
  }
}

resource "haproxy-dataplane_frontend_bind" "sd" {
  parent_name = haproxy-dataplane_frontend.sd.name
  name        = "http"
  spec = {
    address = "*"
    port    = 18082
  }
}

resource "haproxy-dataplane_acme" "letsencrypt" {
  name = "letsencrypt_${var.name_suffix}"
  spec = {
    directory = "https://acme-staging-v02.api.letsencrypt.org/directory"
  }
}

resource "haproxy-dataplane_userlist" "itest" {
  name = "itest_userlist_${var.name_suffix}"
  spec = {}
}

resource "haproxy-dataplane_group" "ops" {
  userlist = haproxy-dataplane_userlist.itest.name
  name     = "ops_${var.name_suffix}"
  spec     = {}
}

resource "haproxy-dataplane_cache" "itest" {
  name = "cache_${var.name_suffix}"
  spec = {
    max_age        = 60
    total_max_size = 4
  }
}

resource "haproxy-dataplane_log_profile" "itest" {
  name = "log_profile_${var.name_suffix}"
  spec = {
    log_tag = "itest-${var.name_suffix}"
  }
}
