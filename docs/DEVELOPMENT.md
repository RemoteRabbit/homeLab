# Development Guide

Guide for contributing to and developing with this K3s homelab repository.

## 🏗️ Architecture Overview

```
K3s Homelab Repository
├── Infrastructure Layer (Ansible + K3s)
├── Application Layer (Kubernetes Manifests)
├── Monitoring Layer (Prometheus + Grafana + Loki)
└── Automation Layer (Scripts + Templates)
```

## 📂 Repository Structure

```
homelab/
├── inventory/              # Ansible inventory and variables
│   ├── hosts.yml          # Node definitions and cluster config
│   └── group_vars/        # Group-specific variables
├── playbooks/             # Ansible playbooks
│   ├── k3s/site.yml      # Main cluster deployment
│   └── monitoring.yml     # Monitoring stack deployment
├── roles/                 # Ansible roles (self-contained)
│   ├── k3s_server/       # K3s server setup + manifests
│   ├── k3s_agent/        # K3s agent setup + manifests
│   └── monitoring/       # Complete monitoring stack + manifests
├── manifests/             # Shared Kubernetes resources
│   ├── templates/        # Application templates
│   ├── apps/            # Generated/deployed applications
│   └── deployments/     # Test deployments
├── scripts/              # Automation scripts
├── docs/                # Documentation
└── README.md           # Main documentation
```

## 🔧 Development Environment Setup

### Prerequisites

```bash
# Required tools
- Ansible >= 2.9
- kubectl >= 1.20
- SSH access to nodes
- sudo privileges on target nodes

# Optional but recommended
- k9s (Kubernetes CLI)
- helm (package manager)
- git
```

### Initial Setup

```bash
# Clone repository
git clone https://github.com/RemoteRabbit/homeLab.git
cd homeLab

# Verify Ansible connectivity
ansible -i inventory/hosts.yml k3s_cluster -m ping

# Deploy K3s cluster (if not already done)
ansible-playbook -i inventory/hosts.yml playbooks/k3s/site.yml

# Verify cluster
kubectl get nodes
```

## 🛠️ Development Workflow

### 1. Infrastructure Changes

```bash
# Make changes to roles/playbooks
# Test on development environment first
ansible-playbook -i inventory/hosts.yml playbooks/k3s/site.yml --check

# Deploy changes
ansible-playbook -i inventory/hosts.yml playbooks/k3s/site.yml

# Verify deployment
kubectl get nodes
kubectl get pods --all-namespaces
```

### 2. Monitoring Changes

```bash
# Edit monitoring manifests in roles/monitoring/files/monitoring/
# Test deployment
ansible-playbook -i inventory/hosts.yml playbooks/monitoring.yml --check

# Deploy changes
ansible-playbook -i inventory/hosts.yml playbooks/monitoring.yml

# Verify monitoring stack
kubectl get pods -n monitoring
```

### 3. Application Development

```bash
# Create new application
./scripts/create-app.sh webapp testapp -i nginx -t latest -p 80 -n 30090

# Test deployment
kubectl apply -f manifests/apps/testapp/ --dry-run=client

# Deploy and test
kubectl apply -f manifests/apps/testapp/
kubectl get pods -n testapp

# Clean up
kubectl delete namespace testapp
```

### 4. Template Development

```bash
# Edit templates in manifests/templates/
# Test with creation script
./scripts/create-app.sh webapp test -i nginx -p 80

# Verify generated manifest
cat manifests/apps/test/deployment.yml

# Clean up
rm -rf manifests/apps/test/
```

## 🧪 Testing Procedures

### Infrastructure Testing

```bash
# Ansible syntax check
ansible-playbook --syntax-check playbooks/k3s/site.yml
ansible-playbook --syntax-check playbooks/monitoring.yml

# Dry run deployment
ansible-playbook -i inventory/hosts.yml playbooks/k3s/site.yml --check

# Verify cluster health
kubectl get componentstatuses
kubectl cluster-info
kubectl get nodes -o wide
```

### Application Testing

```bash
# Test application creation
./scripts/create-app.sh webapp nginx-test -i nginx -p 80 -n 30099

# Validate Kubernetes manifests
kubectl apply -f manifests/apps/nginx-test/ --dry-run=client -o yaml

# Deploy and test
kubectl apply -f manifests/apps/nginx-test/
kubectl wait --for=condition=available --timeout=300s deployment/nginx-test -n nginx-test

# Test connectivity
curl -I http://10.10.1.24:30099

# Clean up
kubectl delete namespace nginx-test
rm -rf manifests/apps/nginx-test/
```

### Monitoring Testing

```bash
# Deploy monitoring stack
ansible-playbook -i inventory/hosts.yml playbooks/monitoring.yml

# Test access
curl -I http://10.10.1.24:30001  # Grafana
curl -I http://10.10.1.24:30000  # Prometheus

# Test metrics collection
curl -s http://10.10.1.24:30000/api/v1/targets | jq '.data.activeTargets[] | .health'

# Test log collection
kubectl logs -n monitoring deployment/promtail
```

## 📋 Code Standards

### Ansible Standards

```yaml
# Task naming
- name: Descriptive task name with action
  module_name:
    param: value
  become: true  # When sudo required
  run_once: true  # For cluster-wide operations
```

### Kubernetes Manifest Standards

```yaml
# Always include
metadata:
  name: app-name
  namespace: app-namespace
  labels:
    app: app-name
    version: v1.0.0
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"

# Always set resource limits
resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 200m
    memory: 256Mi

# Include health checks
livenessProbe:
  httpGet:
    path: /health
    port: 8080
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
```

### Script Standards

```bash
#!/bin/bash
set -e  # Exit on error

# Color functions
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

print_error() { echo -e "${RED}❌${NC} $1"; }
print_success() { echo -e "${GREEN}✅${NC} $1"; }

# Include usage function
usage() {
    echo "Usage: $0 <args>"
    echo "Description of script"
}
```

## 🔍 Debugging

### Common Issues

```bash
# Ansible connection issues
ansible -i inventory/hosts.yml k3s_cluster -m setup
ssh -i ~/.ssh/key user@node-ip sudo echo "test"

# K3s issues
sudo systemctl status k3s
sudo journalctl -u k3s -f
kubectl describe nodes

# Pod issues
kubectl get pods -n namespace -o wide
kubectl describe pod pod-name -n namespace
kubectl logs pod-name -n namespace --previous

# Network issues
kubectl exec -it pod-name -n namespace -- nslookup kubernetes.default
kubectl get svc,endpoints -n namespace
```

### Debug Commands

```bash
# Cluster debug info
kubectl cluster-info dump > cluster-debug.txt

# Node resource usage
kubectl top nodes
kubectl describe nodes | grep -A 5 "Allocated resources"

# Pod resource usage
kubectl top pods --all-namespaces
kubectl get pods --all-namespaces -o wide

# Network debugging
kubectl exec -it debug-pod -- ping service-name
kubectl exec -it debug-pod -- nslookup service-name.namespace.svc.cluster.local
```

## 📦 Release Process

### Version Management

```bash
# Tag versions
git tag -a v1.0.0 -m "Release v1.0.0: Initial monitoring stack"
git push origin v1.0.0

# Update README with version info
# Update CHANGELOG.md
```

### Testing Checklist

- [ ] All Ansible playbooks pass syntax check
- [ ] K3s cluster deploys successfully
- [ ] All monitoring components start correctly
- [ ] Application creation script works
- [ ] Documentation is up to date
- [ ] No secrets committed to repository

## 🤝 Contributing

### Pull Request Process

1. **Fork and branch**
   ```bash
   git checkout -b feature/new-monitoring-dashboard
   ```

2. **Make changes with tests**
   ```bash
   # Make changes
   # Test thoroughly
   ./scripts/create-app.sh webapp test-pr -i nginx -p 80
   kubectl apply -f manifests/apps/test-pr/
   ```

3. **Update documentation**
   ```bash
   # Update relevant README files
   # Add/update examples
   ```

4. **Submit PR with description**
   - What changes were made
   - Why they were needed
   - How to test the changes
   - Any breaking changes

### Review Criteria

- Code follows established patterns
- Changes are well tested
- Documentation is updated
- No credentials or secrets included
- Backward compatibility maintained
- Resource limits are appropriate

## 🚀 Advanced Topics

### Custom Roles

```bash
# Create new role
mkdir -p roles/new-service/{tasks,defaults,files,handlers}

# Role structure
roles/new-service/
├── tasks/main.yml
├── defaults/main.yml
├── files/manifests/
└── README.md
```

### Multi-Environment Support

```bash
# Different inventory files
inventory/
├── dev-hosts.yml
├── prod-hosts.yml
└── group_vars/
    ├── dev/
    └── prod/
```

### CI/CD Integration

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Test Ansible syntax
        run: |
          ansible-playbook --syntax-check playbooks/k3s/site.yml
          ansible-playbook --syntax-check playbooks/monitoring.yml
```

## 📚 Additional Resources

- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [K3s Documentation](https://docs.k3s.io/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

---

Happy developing! 🚀
