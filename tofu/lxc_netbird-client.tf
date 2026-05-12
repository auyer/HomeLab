locals{
  netbird_client_id = 105
}

resource "proxmox_lxc" "netbird_client" {
  target_node  = var.proxmox_node
  vmid         = local.netbird_client_id
  hostname     = "netbird.client"
  ostemplate   = data.external.debian_template.result.path
  unprivileged = true
  onboot       = true
  start        = true

  cores  = 1
  memory = 1024
  swap   = 0

  ssh_public_keys = var.ssh_key

  rootfs {
    storage = "nvme512"
    size    = "10G"
  }

  network {
    name     = "eth0"
    bridge   = var.nic_name
    ip       = "10.255.0.105/22"
    gw       = "10.255.0.1"
    firewall = true
  }

  features {
    nesting = true
  }

  # We REMOVED the mountpoint block from here to avoid the 403 error.
}

# This resource handles the "Root-Only" configurations via SSH
resource "null_resource" "netbird_client_config_overrides" {
  depends_on = [proxmox_lxc.netbird_client]

  connection {
    type = "ssh"
    user = "root"
    # Use your host's IP and your local SSH key to access the PVE node
    host        = var.proxmox_host
    private_key = file("~/.ssh/id_ed25519")
  }


  provisioner "remote-exec" {
    inline = [
      # lxc.cgroup2.devices.allow: c 10:200 rwm
      # lxc.mount.entry: /dev/net dev/net none bind,create=dir
      # lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
      # 1. Add the Bind Mount
      "pct set ${local.netbird_client_id} -dev0 path=/dev/net/tun",
      # "pct set ${local.netbird_client_id} -mp0 /dev/net,mp=/dev/net",
      # "pct set ${local.netbird_client_id} -mp1 /dev/net/tun,mp=/dev/net/tun",

      # 2. Restart the container to apply hardware/idmap changes safely
      "if pct status ${local.netbird_client_id} | grep -q 'running'; then pct stop ${local.netbird_client_id} && sleep 2 && pct start ${local.netbird_client_id}; else pct start ${local.netbird_client_id}; fi"
    ]
  }
}

