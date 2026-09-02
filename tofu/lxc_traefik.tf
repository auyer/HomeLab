resource "proxmox_lxc" "traefik" {
  target_node  = var.proxmox_node
  vmid         = 202
  hostname     = "traefik"
  ostemplate   = data.external.debian_template.result.path
  unprivileged = true
  onboot       = true
  start        = true

  cores  = 1
  memory = 2048
  swap   = 0

  ssh_public_keys = var.ssh_key

  rootfs {
    storage = "local-lvm"
    size    = "6G"
  }

  network {
    name     = "eth0"
    bridge   = var.nic_name
    ip       = "10.255.2.2/22"
    gw       = "10.255.0.1"
    firewall = true
  }

  features {
    nesting = true
  }

}
