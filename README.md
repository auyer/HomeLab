# Homelab infrastructure

I've been running my Homelab manually configuring thing for years.
Recently, I finally decided to start moving things to IaC.
I started with my Prosody setup, with Ansible.
Maybe someday I will import the LXCs and VMs to Terraform too.

## This repository contains:

OpenTofu (Terraform) configurations in the [tofu](tofu) folder.
Ansible confis under [ansible](andible) folder.

## XMPP Infrastructure Configuration (Prosody + Biboumi + Angie + Coturn)

Ansible role-based project to install, configure, and manage four XMPP infrastructure services:

| Service  | Host          | Group    | SSH User |
|----------|---------------|----------|----------|
| Prosody  | 10.255.2.27   | prosody  | root     |
| Biboumi  | 10.255.2.27   | prosody  | root     |
| Angie    | 10.255.0.100  | pi       | auyer    |
| Coturn   | 10.255.2.28   | coturn   | root     |

## Directory Layout

Follows [Ansible best practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html#directory-layout): roles encapsulate all logic, playbooks are thin orchestrators.

```
ansible
├── ansible.cfg              # Ansible settings (roles path, inventory)
├── site.yml                 # Master playbook — deploys all services
├── prosody.yml              # Single-service playbook (Prosody only)
├── biboumi.yml              # Single-service playbook (Biboumi only)
├── angie.yml                # Single-service playbook (Angie only)
├── coturn.yml               # Single-service playbook (Coturn only)
├── inventory                # Host groups and SSH connection details
├── group_vars/
│   ├── ....yml              # Shared vars (domain, backend IPs, TURN secret)
└── roles/
    ├── prosody/
    │   ├── tasks/main.yml      # Install packages, community modules, deploy configs
    │   ├── handlers/main.yml   # Config check + service restart
    │   ├── templates/          # Jinja2 configs → rendered with variables
    │   ├── files/              # Static configs → copied as-is
    │   │   ├── conf.d/         # Active vhost/component configs
    │   │   └── conf.avail/     # Available vhost templates
    │   └── defaults/main.yml   # Overridable vars (community module list)
    ├── biboumi/
    │   ├── tasks/main.yml      # Install package, create db dir, deploy config
    │   ├── handlers/main.yml   # Service restart
    │   ├── templates/          # Jinja2 biboumi.cfg
    │   └── defaults/main.yml   # Overridable vars (host, password, DB, XMPP server)
    ├── angie/
    │   ├── tasks/main.yml      # Install repo + package, deploy configs
    │   ├── handlers/main.yml   # Config test + reload
    │   ├── templates/          # .j2 files (angie.conf, prosody.conf, stream configs)
    │   ├── files/              # Static files (host-meta, Pi-hole, Uptime Kuma)
    │   └── defaults/main.yml   # Overridable vars (SSL cert paths)
    └── coturn/
        ├── tasks/main.yml      # Install package, enable daemon, deploy config
        ├── handlers/main.yml   # Service restart
        ├── templates/          # Jinja2 turnserver.conf
        └── defaults/main.yml   # Overridable vars
```

### Static vs Templated Files

| Type       | Location                | Module  | When to Use                          |
|------------|-------------------------|---------|--------------------------------------|
| **Static** | `roles/<name>/files/`   | `copy`  | No environment-specific values       |
| **Template**| `roles/<name>/templates/`| `template`| Contains `{{ variables }}` (IPs, secrets, etc.) |

Both `files/` and `templates/` mirror the remote directory structure (e.g., `files/conf.d/`, `templates/stream.d/`).

### Angie Hybrid Deploy (Static + Template Override)

The Angie role deploys `conf.d/` in two passes:

1. **Static copy** — all files from `roles/angie/files/conf.d/`
2. **Templated override** — any `.j2` file in `roles/angie/templates/conf.d/` replaces the static copy

Same pattern for `stream.d/`. This lets you keep simple files static while templating only the ones that need variables.

## Variables

### Biboumi-Specific (role defaults)

| Variable                | Description                     | Default                  |
|-------------------------|---------------------------------|--------------------------|
| `biboumi_hostname`     | XMPP component hostname         | `biboumi.example.com`   |
| `biboumi_password`     | XMPP component password          | (set in group_vars)     |
| `biboumi_db_dir`        | SQLite database directory        | `/opt/biboumi`          |
| `biboumi_xmpp_server_ip`| XMPP server to connect to       | `127.0.0.1`             |
| `biboumi_port`         | XMPP component port              | `5347`                  |

### Role Defaults (roles/*/defaults/main.yml)

Override these by setting the same variable in `group_vars/` or via `-e` on the CLI.

## Usage

### Deploy Everything

```bash
ansible-playbook site.yml
```

### Deploy a Single Service

```bash
ansible-playbook prosody.yml
ansible-playbook biboumi.yml
ansible-playbook angie.yml
ansible-playbook coturn.yml
```

### Dry Run

```bash
ansible-playbook site.yml --check --diff
```

### Limit to Specific Hosts

```bash
ansible-playbook site.yml --limit 10.255.2.27
ansible-playbook site.yml --limit prosody
```

### Override Variables at Runtime

```bash
ansible-playbook site.yml \
  -e prosody_db_password=newsecret \
  -e prosody_backend=192.168.1.50
```

### With Password Authentication

```bash
ansible-playbook site.yml --ask-pass --ask-become-pass
```

## What Happens on Each Run

1. **Prosody**: packages installed → community modules checked/installed → configs templated/copied → `prosodyctl check config` → restart
2. **Biboumi**: package installed → SQLite database dir created → config templated → service enabled and started
3. **Angie**: repository + signing key added → package installed → main config + conf.d/ + stream.d/ deployed → `angie -t` → reload
4. **Coturn**: package installed → daemon enabled in `/etc/default/coturn` → config templated → restart

Handlers only fire when files actually **changed**, so unchanged runs are fast and safe.

## File Ownership

| Service | Owner      | Mode |
|---------|------------|------|
| Prosody | `root:root`| 0644 |
| Biboumi | `_biboumi:_biboumi`| 0640 |
| Angie   | `angie:angie`| 0644 |
| Coturn  | `root:root`| 0644 |

## Importing Configurations from Servers

When a config file is modified directly on a server, sync it back:

```bash
# From Prosody
rsync -avz root@10.255.2.27:/etc/prosody/conf.d/rcpassosme.cfg.lua roles/prosody/files/conf.d/

# From Biboumi
rsync -avz root@10.255.2.27:/etc/biboumi/biboumi.cfg roles/biboumi/templates/biboumi.cfg.j2

# From Coturn
rsync -avz root@10.255.2.28:/etc/turnserver.conf roles/coturn/templates/turnserver.conf.j2

# From Angie (needs sudo)
rsync -avz --rsync-path="sudo rsync" auyer@10.255.0.100:/etc/angie/conf.d/prosody.conf roles/angie/files/conf.d/
```

### Decide: Static or Template?

- **Static** → place in `roles/<name>/files/<path>/`
- **Template** (contains IPs, secrets, etc.) → place in `roles/<name>/templates/<path>.j2` and replace hardcoded values with `{{ var }}`

## SSH Requirements

- **Prosody** / **Biboumi** / **Coturn**: SSH as `root` (no sudo needed)
- **Angie**: SSH as `auyer` with `sudo` (handled by `become: true`)

Ensure your SSH keys are loaded. The inventory file defines connection parameters per host.
