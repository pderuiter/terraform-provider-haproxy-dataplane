provider "haproxy-dataplane" {
  endpoint = "http://127.0.0.1:5555"
  username = "admin"
  password = "adminpwd"
}

resource "haproxy-dataplane_frontend" "public" {
  name = "fe_public"

  spec = {
    mode = "http"
  }
}

resource "haproxy-dataplane_frontend_bind" "http" {
  parent_name = haproxy-dataplane_frontend.public.name
  name        = "http"

  spec = {
    address = "*"
    port    = 80
  }
}
