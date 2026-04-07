# XMPP Infrastructure Configuration (Prosody + Angie + Coturn)

Ansible role-based project to install, configure, and manage three XMPP infrastructure services:

| Service  | Host          | Group    | SSH User |
|----------|---------------|----------|----------|
| Prosody  | 10.255.2.27   | prosody  | root     |
| Angie    | 10.255.0.100  | pi       | auyer    |
| Coturn   | 10.255.2.28   | coturn   | root     |

## Directory Layout

Follows [Ansible best practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html#directory-layout): roles encapsulate all logic, playbooks are thin orchestrators.

```
.
├── ansible.cfg              # Ansible settings (roles path, inventory)
├── site.yml                 # Master playbook — deploys all services
├── prosody.yml              # Single-service playbook (Prosody only)
├── angie.yml                # Single-service playbook (Angie only)
├── coturn.yml               # Single-service playbook (Coturn only)
├── inventory                # Host groups and SSH connection details
├── group_vars/
│   ├── all.yml              # Shared vars (domain, backend IPs, TURN secret)
│   ├── prosody.yml          # Prosody-specific vars (DB creds, trusted proxies)
│   ├── pi.yml               # Angie server vars
│   └── coturn.yml           # Coturn-specific vars
└── roles/
    ├── prosody/
    │   ├── tasks/main.yml      # Install packages, community modules, deploy configs
    │   ├── handlers/main.yml   # Config check + service restart
    │   ├── templates/          # Jinja2 configs → rendered with variables
    │   ├── files/              # Static configs → copied as-is
    │   │   ├── conf.d/         # Active vhost/component configs
    │   │   └── conf.avail/     # Available vhost templates
    │   └── defaults/main.yml   # Overridable vars (community module list)
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

### Shared (group_vars/all.yml)

| Variable              | Description                     | Default                  |
|-----------------------|---------------------------------|--------------------------|
| `xmpp_domain`         | Primary XMPP domain             | `chat.rcpassos.me`       |
| `xmpp_admin`          | Admin JID                       | `auyer@chat.rcpassos.me` |
| `prosody_backend`     | Prosody server IP               | `10.255.2.27`            |
| `coturn_backend`      | Coturn server IP                | `10.255.2.28`            |
| `angie_resolver_dns`  | DNS resolvers for Angie         | `10.255.0.100 10.255.0.101` |
| `turn_external_secret`| TURN shared secret              | (see group_vars)         |
| `turn_external_host`  | TURN server hostname            | `turn.chat.rcpassos.me`  |

### Prosody-Specific (group_vars/prosody.yml)

| Variable                | Description                     |
|-------------------------|---------------------------------|
| `prosody_db_password`   | PostgreSQL password             |
| `prosody_db_host`       | PostgreSQL hostname             |
| `prosody_trusted_proxies`| Comma-separated trusted proxy IPs|
| `prosody_community_modules`| List of modules to install    |

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
2. **Angie**: repository + signing key added → package installed → main config + conf.d/ + stream.d/ deployed → `angie -t` → reload
3. **Coturn**: package installed → daemon enabled in `/etc/default/coturn` → config templated → restart

Handlers only fire when files actually **changed**, so unchanged runs are fast and safe.

## File Ownership

| Service | Owner      | Mode |
|---------|------------|------|
| Prosody | `root:root`| 0644 |
| Angie   | `angie:angie`| 0644 |
| Coturn  | `root:root`| 0644 |

## Importing Configurations from Servers

When a config file is modified directly on a server, sync it back:

```bash
# From Prosody
rsync -avz root@10.255.2.27:/etc/prosody/conf.d/rcpassosme.cfg.lua roles/prosody/files/conf.d/

# From Coturn
rsync -avz root@10.255.2.28:/etc/turnserver.conf roles/coturn/templates/turnserver.conf.j2

# From Angie (needs sudo)
rsync -avz --rsync-path="sudo rsync" auyer@10.255.0.100:/etc/angie/conf.d/prosody.conf roles/angie/files/conf.d/
```

### Decide: Static or Template?

- **Static** → place in `roles/<name>/files/<path>/`
- **Template** (contains IPs, secrets, etc.) → place in `roles/<name>/templates/<path>.j2` and replace hardcoded values with `{{ var }}`

### Commit and Deploy

```bash
git add roles/ group_vars/
git commit -m "sync: import updated config from server"
ansible-playbook site.yml
```

## SSH Requirements

- **Prosody** / **Coturn**: SSH as `root` (no sudo needed)
- **Angie**: SSH as `auyer` with `sudo` (handled by `become: true`)

Ensure your SSH keys are loaded. The inventory file defines connection parameters per host.

## Security Note

Secrets live in `group_vars/` files. For a shared repository, migrate sensitive values to **Ansible Vault**:

```bash
ansible-vault encrypt group_vars/prosody.yml
ansible-playbook site.yml --ask-vault-pass
```
