locals {
  fcgi_app_name = "managed_fcgi_app"
}

resource "haproxy-dataplane_fcgi_app" "managed" {
  name = local.fcgi_app_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "fcgi_app_id" {
  value = haproxy-dataplane_fcgi_app.managed.id
}
