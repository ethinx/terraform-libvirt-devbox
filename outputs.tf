output "ips" {
  value = libvirt_domain.terraform.*.network_interface.0.addresses.0
}
