resource "proxmox_lxc" "proxy" {
  target_node  = var.proxmox_node
  vmid         = 102
  hostname     = "proxy"
  ostemplate   = data.external.debian_template.result.path
  unprivileged = true
  onboot       = true
  start        = true

  cores  = 1
  memory = 2048
  swap   = 0

  ssh_public_keys = var.ssh_key

  rootfs {
    storage = "nvme512"
    size    = "8G"
  }

  network {
    name     = "eth0"
    bridge   = var.nic_name
    ip       = "10.255.0.102/22"
    gw       = "10.255.0.1"
    firewall = true
  }

  features {
    nesting = true
  }

}
