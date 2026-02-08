locals {
  userlist_lookup_name = "existing_userlist"
}

data "haproxy-dataplane_userlist" "selected" {
}

output "userlist_id" {
  value = data.haproxy-dataplane_userlist.selected.id
}
