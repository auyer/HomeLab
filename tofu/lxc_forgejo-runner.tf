resource "proxmox_lxc" "forgejo-runner" {
  target_node  = var.proxmox_node
  vmid         = 10130
  hostname     = "forgejo-runner"
  ostemplate   = data.external.debian_template.result.path
  unprivileged = true
  onboot       = true
  start        = true

  cores  = 3
  memory = 5120
  swap   = 0

  ssh_public_keys = var.ssh_key

  rootfs {
    storage = "nvme512"
    size    = "50G"
  }

  network {
    name     = "eth0"
    bridge   = var.nic_name
    ip       = "10.255.2.130/22"
    gw       = "10.255.0.1"
    firewall = true
  }

  features {
    nesting = true
  }

}
