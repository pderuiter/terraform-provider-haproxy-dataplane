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
      algorithm = "roundrobin"
    }
  }
}
