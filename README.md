# home-lab

I've been running my Homelab manually configuring thing for years.
Recently, I finally decided to start moving things to IaC.
I started with my Prosody setup, with Ansible.
Infrastructure-as-Code for my homelab — Proxmox LXCs, Kubernetes, and application deployment.

Now, it includes XMPP infrastructure (Prosody, Coturn, Angie, Biboumi, Slidge), Matrix, uptime-kuma, alongside a full observability stack (Grafana, Prometheus, Loki, Alloy).

Main IaC tools:
- **OpenTofu** (Terraform). Declarative setup,for provisioning in API driven providers (like my Proxmox server).
- **Ansible** . Glorified & repeatable configuration and maintence scripts.


## What's in here

| Directory | Purpose |
|---|---|
| [`ansible/`](ansible/) | Custom Ansible roles and playbooks for deploying services. Uses Docker/Podman Compose via a generic [`compose`](ansible/roles/compose/) role, plus native service roles for Prosody, Coturn, Angie, Navidrome, and others. |
| [`appdata/`](appdata/) | Application configs and Compose templates consumed by the `compose` Ansible role. Includes Traefik, Grafana, Loki, Uptime Kuma, NetBird, Forgejo/GitLab runners, NUT, and more. |
| [`k3s/`](k3s/) | Ansible playbooks for deploying a K3s cluster (3 nodes), using the upstream [`k3s-io/k3s-ansible`](https://github.com/k3s-io/k3s-ansible) as a git submodule. |
| [`helm/`](helm/) | Helm charts and raw Kubernetes manifests for the K3s cluster (cert-manager, Rancher, NFS provisioner, Uptime Kuma, metrics-server, Traefik config). Each subdirectory has a `Makefile` with `upgrade`/`apply` targets, orchestrated by the root `Makefile`. |
| [`tofu/`](tofu/) | OpenTofu configurations provisioning LXC containers on Proxmox for each service host. |

## Quick start

```bash
# Provision LXCs on Proxmox
cd tofu && tofu init && tofu apply

# Deploy services via Ansible
cd ansible && ansible-playbook site.yml

# Bootstrap the K3s cluster
cd k3s && ansible-playbook site.yml

# Deploy Helm charts
cd helm && make
```
