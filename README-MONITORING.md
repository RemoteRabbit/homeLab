# 📊 K3s Homelab Monitoring Stack

> **Quick Setup**: Complete monitoring solution for your K3s homelab in one command!

## 🎯 Quick Start

```bash
# Deploy everything
ansible-playbook -i inventory/hosts.yml playbooks/monitoring.yml

# Access your dashboards
# Grafana: http://10.10.1.24:30001 (admin/admin)
# Prometheus: http://10.10.1.24:30000
```

## 🏗️ What Gets Deployed

| Component | Purpose | Access |
|-----------|---------|--------|
| 📊 **Prometheus** | Metrics collection & alerts | `:30000` |
| 📈 **Grafana** | Beautiful dashboards | `:30001` |
| 📝 **Loki** | Log aggregation | Internal |
| 🔍 **Promtail** | Log collector | DaemonSet |
| 💻 **Node Exporter** | System metrics | DaemonSet |
| ☸️ **Kube State Metrics** | K8s cluster state | Internal |

## 🚨 Built-in Monitoring

✅ **System Alerts**
- CPU usage >80%
- Memory usage >90%
- Node down >5min

✅ **Kubernetes Alerts**
- Pod crash looping
- Node not ready
- Memory pressure

✅ **Log Collection**
- All pod logs
- System logs
- Application logs

## 📚 Documentation

For detailed setup, configuration, and troubleshooting:
**[📖 Complete Documentation](docs/MONITORING.md)**

## 📁 File Structure

```
├── manifests/monitoring/          # Kubernetes manifests
│   ├── namespace.yml
│   ├── prometheus-*.yml
│   ├── grafana-*.yml
│   ├── loki-deployment.yml
│   ├── promtail-deployment.yml
│   ├── node-exporter.yml
│   └── kube-state-metrics.yml
├── roles/monitoring/              # Ansible role
│   ├── tasks/main.yml
│   ├── defaults/main.yml
│   └── files/monitoring/
├── playbooks/monitoring.yml       # Main deployment playbook
└── docs/MONITORING.md             # Detailed documentation
```

## 🛠️ Alternative Installation Methods

### Manual kubectl
```bash
kubectl apply -f manifests/monitoring/
```

### Individual Components
```bash
kubectl apply -f manifests/monitoring/namespace.yml
kubectl apply -f manifests/monitoring/prometheus-rbac.yml
kubectl apply -f manifests/monitoring/prometheus-config.yml
kubectl apply -f manifests/monitoring/prometheus-deployment.yml
# ... etc
```

## 🎨 Popular Grafana Dashboards to Import

| ID | Dashboard | Description |
|----|-----------|-------------|
| `12119` | K8s Cluster Overview | Complete cluster monitoring |
| `315` | K8s Cluster Monitoring | Detailed cluster metrics |
| `1860` | Node Exporter Full | System-level monitoring |
| `13332` | Kube State Metrics | K8s object state |

## 🔍 Quick Log Queries

Access logs via Grafana Explore (`:30001/explore`):

```logql
# All monitoring namespace logs
{namespace="monitoring"}

# Error logs cluster-wide
{} |= "error"

# Specific application logs
{app="nginx"}

# Last hour of logs
{namespace="default"}[1h]
```

## 🆘 Quick Troubleshooting

```bash
# Check all monitoring pods
kubectl get pods -n monitoring

# Check specific component logs
kubectl logs -n monitoring deployment/prometheus
kubectl logs -n monitoring deployment/grafana

# Check resource usage
kubectl top pods -n monitoring
kubectl top nodes
```

## 🔄 Updates & Maintenance

```bash
# Update images (edit manifests)
kubectl apply -f manifests/monitoring/

# Restart components
kubectl rollout restart deployment/prometheus -n monitoring
kubectl rollout restart deployment/grafana -n monitoring

# Check status
kubectl rollout status deployment/prometheus -n monitoring
```

---

**🎉 Happy Monitoring!**

For detailed configuration, troubleshooting, and advanced features, see [📖 Complete Documentation](docs/MONITORING.md)
