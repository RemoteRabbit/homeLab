# Ansible Roles

This directory contains Ansible roles for automating homelab infrastructure.

## Available Roles

### Infrastructure Roles
- **`prereq/`** - Prerequisites and system preparation
- **`raspberrypi/`** - Raspberry Pi specific configurations
- **`airgap/`** - Air-gapped installation support

### K3s Cluster Roles
- **`k3s_server/`** - K3s server node setup
- **`k3s_agent/`** - K3s agent node setup
- **`k3s_upgrade/`** - K3s version upgrades

### Application Roles
- **`monitoring/`** - Complete monitoring stack (Prometheus, Grafana, Loki)

## Role Structure

Each role follows standard Ansible structure:

```
role-name/
├── tasks/main.yml         # Main task file
├── defaults/main.yml      # Default variables
├── files/                 # Static files (Kubernetes manifests, configs)
├── templates/             # Jinja2 templates
├── handlers/main.yml      # Handlers
├── vars/main.yml         # Role-specific variables
└── README.md             # Role documentation
```

## Usage

### Individual Roles
```bash
# Run specific role
ansible-playbook -i inventory/hosts.yml --tags prereq playbooks/k3s/site.yml
```

### Full Deployment
```bash
# Deploy complete K3s cluster
ansible-playbook -i inventory/hosts.yml playbooks/k3s/site.yml

# Deploy monitoring
ansible-playbook -i inventory/hosts.yml playbooks/monitoring.yml
```

## Adding New Roles

1. Create role directory structure:
```bash
mkdir -p roles/new-role/{tasks,defaults,files,templates,handlers,vars}
```

2. Create main task file:
```bash
touch roles/new-role/tasks/main.yml
touch roles/new-role/defaults/main.yml
touch roles/new-role/README.md
```

3. Add role to playbook:
```yaml
roles:
  - role: new-role
```

## Best Practices

- Keep manifests within role `files/` directories
- Use meaningful task names and descriptions
- Set appropriate `run_once` for cluster-wide operations
- Include resource limits and security contexts
- Document role variables and usage
- Test roles on development environment first
