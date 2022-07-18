# terraform-libvirt-devbox

For test purpose only.

```
terraform {
  required_version = ">= 0.12"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

# RSA key of size 4096 bits
resource "tls_private_key" "cluster-ssh-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

data "tls_public_key" "cluster-ssh-pub-key" {
  private_key_openssh = tls_private_key.cluster-ssh-key.private_key_openssh
}

module "devbox" {
  source = "../modules/terraform-libvirt-devbox/"
  # the hostname of the devbox will be in format
  # ${project}${idx}.${kind}.${colo}.${org_domain}
  project   = "devbox"
  kind      = "compute"
  vm_count  = 2
  cpu       = 2
  memory    = 4096
  github_id = "ethinx"
  cluster_ssh_pub_key    = data.tls_public_key.cluster-ssh-pub-key.public_key_openssh
  cluster_ssh_secret_key = tls_private_key.cluster-ssh-key.private_key_openssh
  libvirt_mode        = "local"
  libvirt_user        = "ethinx"
  libvirt_remote_host = "localhost"
}

output "devbox-ips" {
  value = module.devbox.ips
}
```
