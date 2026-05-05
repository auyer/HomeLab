# Use the script to find the latest template name 
data "external" "debian_template" {
  program = ["bash", "${path.module}/find_template.sh", var.proxmox_host, var.template_name]
}
