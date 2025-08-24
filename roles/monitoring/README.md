# Monitoring Ansible Role

Ansible role to deploy a complete monitoring stack to K3s clusters.

## Features

- 📊 **Prometheus**: Metrics collection with Kubernetes service discovery
- 📈 **Grafana**: Pre-configured dashboards and data sources
- 📝 **Loki + Promtail**: Complete log aggregation solution
- 💻 **Node Exporter**: System-level metrics for all nodes
- ☸️ **Kube State Metrics**: Kubernetes cluster state monitoring
- 🚨 **Alerting**: Built-in alerts for common issues

## Role Variables

Available variables in `defaults/main.yml`:

```yaml
# Kubernetes configuration
kubeconfig_path: "~/.kube/config"
monitoring_namespace: monitoring

# Prometheus configuration
prometheus_retention_time: "30d"
prometheus_storage_size: "10Gi"

# Grafana configuration
grafana_admin_user: admin
grafana_admin_password: admin
grafana_domain: "grafana.homelab.local"

# Resource limits
prometheus_memory_limit: "1Gi"
prometheus_cpu_limit: "1000m"
grafana_memory_limit: "1Gi"
grafana_cpu_limit: "1000m"
loki_memory_limit: "1Gi"
loki_cpu_limit: "1000m"

# NodePort configuration
grafana_nodeport: 30001
prometheus_nodeport: 30000
```

## Dependencies

- K3s cluster with kubectl access
- Ansible `shell` module support

## Example Playbook

```yaml
---
- name: Deploy monitoring stack
  hosts: server[0]
  gather_facts: true
  become: true
  vars:
    kubeconfig_path: "/etc/rancher/k3s/k3s.yaml"
    grafana_admin_password: "mysecretpassword"
  roles:
    - role: monitoring
```

## Example with Custom Variables

```yaml
---
- name: Deploy monitoring with custom config
  hosts: k3s_servers
  gather_facts: true
  become: true
  vars:
    # Custom resource limits for smaller cluster
    prometheus_memory_limit: "512Mi"
    prometheus_cpu_limit: "500m"
    grafana_memory_limit: "256Mi"
    grafana_cpu_limit: "250m"

    # Custom retention
    prometheus_retention_time: "15d"

    # Different ports
    grafana_nodeport: 31000
    prometheus_nodeport: 31001
  roles:
    - role: monitoring
```

## Tasks Overview

1. **Pre-flight checks**: Verify kubeconfig permissions
2. **File preparation**: Copy manifest files to target
3. **Namespace creation**: Create monitoring namespace
4. **Component deployment**: Deploy all monitoring components
5. **Health checks**: Wait for deployments to be ready
6. **Cleanup**: Remove temporary files

## Files Structure

```
roles/monitoring/
├── tasks/main.yml              # Main task file
├── defaults/main.yml           # Default variables
├── files/monitoring/           # Kubernetes manifests
│   ├── namespace.yml
│   ├── prometheus-rbac.yml
│   ├── prometheus-config.yml
│   ├── prometheus-deployment.yml
│   ├── grafana-config.yml
│   ├── grafana-deployment.yml
│   ├── loki-deployment.yml
│   ├── promtail-deployment.yml
│   ├── node-exporter.yml
│   └── kube-state-metrics.yml
└── README.md                   # This file
```

## Deployment Process

The role performs these steps:

1. **Check kubeconfig file** permissions and accessibility
2. **Create temporary directory** for manifest files
3. **Copy all manifests** to target server
4. **Deploy namespace** and wait for readiness
5. **Deploy RBAC** configurations for Prometheus
6. **Deploy Prometheus** with configuration and wait for ready
7. **Deploy Grafana** with data sources and wait for ready
8. **Deploy Loki** for log aggregation
9. **Deploy Promtail** as DaemonSet for log collection
10. **Deploy Node Exporter** as DaemonSet for system metrics
11. **Deploy Kube State Metrics** for cluster state
12. **Cleanup** temporary files

## Post-Deployment

After successful deployment, the role displays:

- Grafana URL and credentials
- Prometheus URL
- List of deployed components
- Next steps for configuration

## Troubleshooting

### Permission Issues

If you encounter kubeconfig permission errors:

```yaml
# Ensure become is enabled
become: true

# Or specify alternative kubeconfig
vars:
  kubeconfig_path: "/path/to/accessible/kubeconfig"
```

### Pod Startup Issues

Check deployment status:

```bash
# Check all pods
kubectl get pods -n monitoring

# Check specific deployment
kubectl describe deployment prometheus -n monitoring

# Check logs
kubectl logs -n monitoring deployment/prometheus
```

### Resource Constraints

For smaller clusters, reduce resource limits:

```yaml
vars:
  prometheus_memory_limit: "256Mi"
  prometheus_cpu_limit: "250m"
  grafana_memory_limit: "128Mi"
  grafana_cpu_limit: "100m"
```

## Development

To modify the role:

1. Update manifest files in `files/monitoring/`
2. Modify tasks in `tasks/main.yml`
3. Update default variables in `defaults/main.yml`
4. Test deployment on development cluster
5. Update documentation

## License

MIT

## Author Information

Created for homelab K3s monitoring automation.
