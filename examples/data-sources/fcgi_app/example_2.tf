locals {
  fcgi_app_lookup_name = "existing_fcgi_app"
}

data "haproxy-dataplane_fcgi_app" "selected" {
}

output "fcgi_app_id" {
  value = data.haproxy-dataplane_fcgi_app.selected.id
}
