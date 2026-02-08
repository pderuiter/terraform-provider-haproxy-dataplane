provider "haproxy-dataplane" {
  endpoint = "http://127.0.0.1:5555"
  username = "admin"
  password = "adminpwd"
}

resource "haproxy-dataplane_backend" "api" {
  name = "be_api"

  spec = {
    mode = "http"
    balance = {
      algorithm = "leastconn"
    }
  }
}

resource "haproxy-dataplane_backend_server" "api_1" {
  parent_name = haproxy-dataplane_backend.api.name
  name        = "api-1"

  spec = {
    address = "10.0.20.11"
    port    = 8080
    check   = "enabled"
    weight  = 100
  }
}
