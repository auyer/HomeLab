resource "proxmox_lxc" "navidrome" {
  target_node  = var.proxmox_node
  vmid         = 156
  hostname     = "navidrome"
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
    size    = "10G"
  }

  network {
    name     = "eth0"
    bridge   = var.nic_name
    ip       = "10.255.2.156/22"
    gw       = "10.255.0.1"
    firewall = true
  }

  features {
    nesting = true
  }

  # We REMOVED the mountpoint block from here to avoid the 403 error.
}

# This resource handles the "Root-Only" configurations via SSH
resource "null_resource" "navidrome_config_overrides" {
  depends_on = [proxmox_lxc.navidrome]

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
      "pct set 156 -mp0 /mnt/pve/nasMedia/jellyfin,mp=/media",

      # 2. Restart the container to apply hardware/idmap changes safely
      "if pct status 156 | grep -q 'running'; then pct stop 156 && sleep 2 && pct start 156; else pct start 156; fi"
    ]
  }
}

