locals {
  userlist_name = "managed_userlist"
}

resource "haproxy-dataplane_userlist" "managed" {
  name = local.userlist_name

  # Replace with required fields for this object in your environment.
  spec = {}
}

output "userlist_id" {
  value = haproxy-dataplane_userlist.managed.id
}
