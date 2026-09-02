locals {
  continuwuity_id = 2900
}

resource "proxmox_lxc" "continuwuity" {
  target_node  = var.proxmox_node
  vmid         = local.continuwuity_id
  hostname     = "continuwuity"
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
    size    = "10G"
  }

  network {
    name     = "eth0"
    bridge   = var.nic_name
    ip       = "10.255.2.29/22"
    gw       = "10.255.0.1"
    firewall = true
  }

  features {
    nesting = true
  }
}

# This resource handles the "Root-Only" configurations via SSH
resource "null_resource" "continuwuity_config_overrides" {
  depends_on = [proxmox_lxc.continuwuity]

  connection {
    type = "ssh"
    user = "root"
    # Use your host's IP and your local SSH key to access the PVE node
    host        = var.proxmox_host
    private_key = file("~/.ssh/id_ed25519")
  }


  provisioner "remote-exec" {
    inline = [
      # 1. Add the Bind Mount
      "pct set ${local.continuwuity_id} -mp0 /mnt/pve/FboxDisks/continuwuity,mp=/opt",

      # 2. Restart the container to apply hardware/idmap changes safely
      "if pct status ${local.continuwuity_id} | grep -q 'running'; then pct stop ${local.continuwuity_id} && sleep 2 && pct start ${local.continuwuity_id}; else pct start ${local.continuwuity_id}; fi"
    ]
  }
}
