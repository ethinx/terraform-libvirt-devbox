terraform {
  required_version = ">= 0.12"
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = var.libvirt_mode == "local" ? "qemu:///system" : "qemu+ssh://${var.libvirt_user}@${var.libvirt_remote_host}/system?known_hosts_verify=ignore&sshauth=privkey"
}

resource "libvirt_pool" "terraform" {
  name = "terraform-${var.project}-${var.kind}"
  type = "dir"
  path = "${var.libvirt_pool_path}/terraform-${var.project}-${var.kind}"
}

resource "libvirt_volume" "os-image" {
  name   = "os-image"
  pool   = libvirt_pool.terraform.name
  format = "qcow2"
  source = "${path.module}/images/jammy-server-cloudimg-amd64.img"
}

resource "libvirt_volume" "os-volume" {
  name           = "os-volume-${var.kind}-${count.index}"
  pool           = "terraform-${var.project}-${var.kind}"
  size           = var.disk_size
  count          = var.vm_count
  base_volume_id = libvirt_volume.os-image.id
}

data "http" "github-pub-keys" {
  url = "https://github.com/${var.github_id}.keys"
}

data "local_file" "ssh-pub-key" {
  filename = pathexpand("~/.ssh/id_rsa.pub")
}

resource "libvirt_cloudinit_disk" "cloud-init-iso" {
  name = "clout-init-${var.project}-${var.kind}-${count.index}.iso"
  user_data = templatefile("${path.module}/cloud-init/cloud_init.cfg",
    {
      idx : "${count.index}",
      project : "${var.project}",
      kind : "${var.kind}",
      colo : "${var.colo}",
      org_domain : "${var.org_domain}",
      github_pub_keys : split("\n", data.http.github-pub-keys.response_body)
      local_pub_key : data.local_file.ssh-pub-key
      cluster_ssh_pub_key : "${var.cluster_ssh_pub_key}"
      cluster_ssh_secret_key : "${var.cluster_ssh_secret_key}"
    }
  )
  network_config = templatefile("${path.module}/cloud-init/network_config.cfg", {})
  pool           = libvirt_pool.terraform.name
  count          = try(var.vm_count, 2)
}

resource "libvirt_domain" "terraform" {
  count  = try(var.vm_count, 2)
  name   = "ubuntu-terraform-${var.project}-${var.kind}-${count.index}"
  memory = var.memory
  vcpu   = var.cpu

  cloudinit = element(libvirt_cloudinit_disk.cloud-init-iso.*.id, count.index)

  provisioner "local-exec" {
    when    = destroy
    command = "ssh-keygen -R ${self.network_interface.0.addresses.0}"
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = element(libvirt_volume.os-volume.*.id, count.index)
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

resource "null_resource" "waiter" {
  count = var.vm_count

  connection {
    host        = element(libvirt_domain.terraform.*.network_interface.0.addresses.0, count.index)
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status -w"
    ]
  }
}
