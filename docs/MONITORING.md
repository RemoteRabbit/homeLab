# K3s Homelab Monitoring Stack

Complete monitoring solution for your K3s homelab cluster with Prometheus, Grafana, Loki, and more.

## 🚀 Overview

This monitoring stack provides comprehensive observability for your K3s homelab:

- **📊 Metrics Collection**: Prometheus scrapes metrics from Kubernetes and system components
- **📈 Visualization**: Grafana dashboards for beautiful charts and graphs
- **📝 Log Aggregation**: Loki collects and indexes logs from all pods and services
- **🚨 Alerting**: Built-in alerts for common issues (high CPU, memory, pod crashes)
- **🔍 System Monitoring**: Node Exporter provides host-level metrics
- **☸️ Kubernetes Monitoring**: Kube State Metrics exposes cluster state

## 📦 Components

| Component | Purpose | Port | Image |
|-----------|---------|------|-------|
| **Prometheus** | Metrics collection & alerting | 30000 | `prom/prometheus:v2.45.0` |
| **Grafana** | Data visualization | 30001 | `grafana/grafana:10.0.3` |
| **Loki** | Log aggregation | 3100 | `grafana/loki:2.9.0` |
| **Promtail** | Log collection agent | - | `grafana/promtail:2.9.0` |
| **Node Exporter** | System metrics | 9100 | `prom/node-exporter:v1.6.1` |
| **Kube State Metrics** | K8s cluster metrics | 8080 | `k8s.gcr.io/kube-state-metrics/kube-state-metrics:v2.10.0` |

## 🛠️ Installation

### Prerequisites

- K3s cluster running (see main [README.md](../README.md))
- Ansible configured and working
- `kubectl` access to your cluster

### Method 1: Ansible Deployment (Recommended)

```bash
# Deploy the complete monitoring stack
ansible-playbook -i inventory/hosts.yml playbooks/monitoring.yml
```

### Method 2: Manual kubectl

```bash
# Apply all manifests at once
kubectl apply -f manifests/monitoring/

# Or apply individually
kubectl apply -f manifests/monitoring/namespace.yml
kubectl apply -f manifests/monitoring/prometheus-rbac.yml
kubectl apply -f manifests/monitoring/prometheus-config.yml
kubectl apply -f manifests/monitoring/prometheus-deployment.yml
kubectl apply -f manifests/monitoring/grafana-config.yml
kubectl apply -f manifests/monitoring/grafana-deployment.yml
kubectl apply -f manifests/monitoring/loki-deployment.yml
kubectl apply -f manifests/monitoring/promtail-deployment.yml
kubectl apply -f manifests/monitoring/node-exporter.yml
kubectl apply -f manifests/monitoring/kube-state-metrics.yml
```

### Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n monitoring

# Check services
kubectl get svc -n monitoring

# Check deployments
kubectl get deployments -n monitoring
```

## 🌐 Access

### URLs

Replace `10.10.1.24` with your K3s server IP address:

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://10.10.1.24:30001 | admin / admin |
| **Prometheus** | http://10.10.1.24:30000 | No auth |

### Port Forwarding (Alternative)

```bash
# Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Prometheus
kubectl port-forward -n monitoring svc/prometheus-service 9090:8080
```

## 📊 Default Dashboards

### Grafana Dashboards

1. **Kubernetes Cluster Resource Usage** - Pre-configured dashboard showing:
   - Cluster CPU and Memory capacity
   - Resource utilization trends
   - Pod and node status

### Import Additional Dashboards

Popular dashboard IDs to import from [grafana.com](https://grafana.com/grafana/dashboards/):

| ID | Name | Description |
|----|------|-------------|
| `12119` | Kubernetes Cluster Overview | Complete K8s cluster monitoring |
| `315` | Kubernetes Cluster Monitoring | Detailed cluster metrics |
| `13332` | Kube State Metrics v2 | Kubernetes object state |
| `1860` | Node Exporter Full | Detailed system metrics |
| `13639` | Logs App | Loki log exploration |

**How to import:**
1. Open Grafana → Dashboards → Import
2. Enter dashboard ID
3. Select Prometheus data source
4. Click Import

## 🚨 Built-in Alerts

### Prometheus Alerts

The following alerts are pre-configured:

| Alert | Condition | Severity |
|-------|-----------|----------|
| `NodeDown` | Node unreachable for >5min | Critical |
| `NodeHighCPUUsage` | CPU usage >80% for 5min | Warning |
| `NodeHighMemoryUsage` | Memory usage >90% for 5min | Critical |
| `KubernetesNodeReady` | Node not ready for 10min | Critical |
| `KubernetesMemoryPressure` | Memory pressure detected | Critical |
| `KubernetesPodCrashLooping` | Pod restart >3 times in 1min | Warning |

### Alert Configuration

To configure alert channels (email, Slack, Discord, etc.):

1. Open Grafana → Alerting → Notification channels
2. Add your preferred notification method
3. Test the configuration

## 📝 Log Management

### Loki Configuration

Loki automatically collects logs from:
- All Kubernetes pods
- System containers
- Application containers

### Viewing Logs

1. **Grafana Explore**: http://10.10.1.24:30001/explore
2. Select "Loki" data source
3. Use LogQL queries:

```logql
# All logs from monitoring namespace
{namespace="monitoring"}

# Logs from specific pod
{pod="prometheus-xxxxx"}

# Error logs across cluster
{} |= "error"

# Logs from specific app
{app="nginx"}
```

## ⚙️ Configuration

### Resource Limits

Default resource limits per component:

```yaml
# Prometheus
resources:
  requests: { cpu: "500m", memory: "500M" }
  limits: { cpu: "1000m", memory: "1Gi" }

# Grafana
resources:
  requests: { cpu: "500m", memory: "500M" }
  limits: { cpu: "1000m", memory: "1Gi" }

# Loki
resources:
  requests: { cpu: "500m", memory: "512Mi" }
  limits: { cpu: "1000m", memory: "1Gi" }
```

### Persistent Storage

⚠️ **Current Setup**: Uses `emptyDir` (ephemeral storage)

**For Production**: Configure persistent volumes:

```yaml
# Add to deployments
volumes:
- name: storage
  persistentVolumeClaim:
    claimName: prometheus-pvc
```

### Data Retention

- **Prometheus**: 30 days (configurable)
- **Loki**: No retention limit (configurable)

## 🔧 Customization

### Adding Custom Metrics

To monitor your applications:

1. **Add metrics endpoint** to your app
2. **Annotate your service**:
   ```yaml
   metadata:
     annotations:
       prometheus.io/scrape: "true"
       prometheus.io/port: "8080"
       prometheus.io/path: "/metrics"
   ```

### Custom Dashboards

1. Create dashboards in Grafana
2. Export JSON
3. Store in version control
4. Import via ConfigMap

### Custom Alerts

Add to `prometheus-config.yml`:

```yaml
groups:
- name: custom
  rules:
  - alert: HighResponseTime
    expr: http_request_duration_seconds > 2
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High response time detected"
```

## 🩺 Troubleshooting

### Common Issues

#### 1. Pods Not Starting

```bash
# Check pod status
kubectl describe pod -n monitoring <pod-name>

# Check logs
kubectl logs -n monitoring <pod-name>
```

#### 2. Prometheus Not Scraping

```bash
# Check Prometheus targets
curl http://10.10.1.24:30000/targets

# Check service discovery
kubectl logs -n monitoring deployment/prometheus
```

#### 3. Grafana Connection Issues

```bash
# Check Grafana logs
kubectl logs -n monitoring deployment/grafana

# Check data source configuration
kubectl get configmap -n monitoring grafana-datasources -o yaml
```

#### 4. Missing Metrics

Common solutions:
- Check service annotations
- Verify network policies
- Check RBAC permissions
- Validate port configurations

### Debugging Commands

```bash
# Get all monitoring resources
kubectl get all -n monitoring

# Check configurations
kubectl get configmaps -n monitoring

# Check persistent volumes (if used)
kubectl get pv,pvc -n monitoring

# Check resource usage
kubectl top pods -n monitoring
kubectl top nodes
```

## 🚀 Next Steps

### Performance Optimization

1. **Add persistent storage** for data retention
2. **Configure resource requests/limits** based on usage
3. **Set up node affinity** for better distribution
4. **Enable scrape interval tuning** for better performance

### Enhanced Security

1. **Enable HTTPS/TLS** for Grafana
2. **Configure RBAC** properly
3. **Set up authentication** (LDAP, OAuth, etc.)
4. **Use secrets** for sensitive configuration

### Advanced Features

1. **High Availability**: Run multiple Prometheus instances
2. **Federation**: Connect multiple Prometheus servers
3. **Remote Storage**: Use external storage backends
4. **Service Mesh**: Integrate with Istio/Linkerd
5. **GitOps**: Automate deployments with ArgoCD

### Monitoring Expansion

1. **Application Metrics**: Add custom application monitoring
2. **Network Monitoring**: Add network policy monitoring
3. **Security Monitoring**: Add Falco for security events
4. **Cost Monitoring**: Add resource cost tracking

## 📚 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/)
- [Kubernetes Monitoring Best Practices](https://kubernetes.io/docs/concepts/cluster-administration/monitoring/)
- [PromQL Tutorial](https://prometheus.io/docs/prometheus/latest/querying/)
- [LogQL Tutorial](https://grafana.com/docs/loki/latest/logql/)

## 🤝 Contributing

Found an issue or want to improve the monitoring setup?

1. Check existing issues
2. Create a pull request
3. Update documentation
4. Test thoroughly

---

**Happy Monitoring!** 📊✨
