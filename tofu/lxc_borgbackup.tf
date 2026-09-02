locals {
  borg_id = 1010
}

resource "proxmox_lxc" "borg" {
  target_node  = var.proxmox_node
  vmid         = local.borg_id
  hostname     = "borg"
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
    ip       = "10.255.1.10/22"
    gw       = "10.255.0.1"
    firewall = true
  }

  features {
    nesting = true
  }
}

# This resource handles the "Root-Only" configurations via SSH
resource "null_resource" "borg_config_overrides" {
  depends_on = [proxmox_lxc.borg]

  connection {
    type = "ssh"
    user = "root"
    # Use your host's IP and your local SSH key to access the PVE node
    host        = var.proxmox_host
    private_key = file("~/.ssh/id_ed25519")
  }


  provisioner "remote-exec" {
    inline = [
      # add Add the Bind Mounts
      "pct set ${local.borg_id} -mp0 /mnt/pve/FboxDisks,mp=/media/fboxdisks",

      "pct set ${local.borg_id} -mp1 /mnt/pve/FboxDisks/borg,mp=/opt/borg",

      # 2. Restart the container to apply hardware/idmap changes safely
      "if pct status ${local.borg_id} | grep -q 'running'; then pct stop ${local.borg_id} && sleep 2 && pct start ${local.borg_id}; else pct start ${local.borg_id}; fi"
    ]
  }
}

