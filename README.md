# K3s HomeLab

Automated K3s cluster deployment and management with comprehensive monitoring and application deployment capabilities.

## 🚀 Quick Start

```bash
# Deploy K3s cluster
ansible-playbook -i inventory/hosts.yml playbooks/k3s/site.yml

# Deploy monitoring stack
ansible-playbook -i inventory/hosts.yml playbooks/monitoring.yml

# Create and deploy a new app
./scripts/create-app.sh webapp myapp -i nginx -t alpine -p 80 -n 30080
kubectl apply -f scripts/generated-apps/myapp/
```

## 📊 Features

- **✅ Automated K3s Deployment**: Single-command cluster setup with Ansible
- **📊 Complete Monitoring Stack**: Prometheus, Grafana, Loki with pre-built dashboards
- **🚀 Application Templates**: Easy deployment of web apps, databases, and multi-service stacks
- **🔍 Log Aggregation**: Centralized logging with Loki and Promtail
- **🚨 Built-in Alerting**: System and application monitoring with alerts
- **📱 NodePort Access**: Direct access to services via node IPs
- **🔧 Infrastructure as Code**: Everything managed through Git and Ansible

## 🏗️ Infrastructure

- **K3s Server**: 10.10.1.24 (1 node)
- **K3s Agents**: 10.10.1.25, 10.10.1.26, 10.10.1.27 (3 nodes)
- **Monitoring**: Prometheus + Grafana + Loki stack
- **Storage**: K3s local-path provisioner
- **Networking**: K3s built-in networking with NodePort services

## 📚 Documentation

### Core Documentation
- 📖 **[Monitoring Guide](docs/MONITORING.md)** - Complete monitoring setup and configuration
- 🚀 **[Adding Applications](docs/ADDING-APPS.md)** - Deploy new services and stacks
- ⚡ **[Quick Monitoring](README-MONITORING.md)** - Fast monitoring deployment reference

### Quick Access
- **Grafana**: http://10.10.1.24:30001 (admin/admin)
- **Prometheus**: http://10.10.1.24:30000

## 🛠️ Project Structure

```
├── inventory/hosts.yml         # Ansible inventory and configuration
├── playbooks/
│   ├── k3s/site.yml           # Main K3s cluster deployment
│   └── monitoring.yml          # Monitoring stack deployment
├── roles/                      # Ansible roles for automation
│   ├── k3s_server/            # K3s server setup
│   ├── k3s_agent/             # K3s agent setup
│   └── monitoring/            # Complete monitoring stack

├── scripts/create-app.sh       # Application creation tool
└── docs/                      # Detailed documentation
```

## 🎯 Application Deployment

### Using Templates

```bash
# Simple web application
./scripts/create-app.sh webapp whoami -i traefik/whoami -t v1.8 -p 80 -n 30080

# Database with persistent storage
./scripts/create-app.sh stateful postgres -i postgres -t 13 -p 5432 -s 10Gi

# Multi-service stack
./scripts/create-app.sh stack todoapp
```

### Available Templates
- **webapp**: Stateless web applications
- **stateful**: Databases and applications requiring persistent storage
- **stack**: Multi-service applications (frontend + backend + database)

## 🔍 Monitoring & Observability

### Built-in Monitoring
- **System Metrics**: CPU, memory, disk, network via Node Exporter
- **Kubernetes Metrics**: Pod, service, deployment status via Kube State Metrics
- **Application Logs**: Automatic log collection from all pods
- **Custom Dashboards**: Pre-built Grafana dashboards for K8s monitoring

### Alerts Included
- Node down >5 minutes
- High CPU usage >80%
- High memory usage >90%
- Pod crash looping
- Kubernetes node not ready

## 🚨 Common Commands

```bash
# Cluster Management
kubectl get nodes
kubectl get pods --all-namespaces
kubectl top nodes

# Application Management
kubectl get pods -n <app-namespace>
kubectl logs -n <app-namespace> deployment/<app-name>
kubectl port-forward -n <app-namespace> svc/<service> 8080:80

# Monitoring
kubectl get pods -n monitoring
kubectl logs -n monitoring deployment/prometheus
kubectl logs -n monitoring deployment/grafana
```

## 🔧 Maintenance

```bash
# Update K3s version (edit inventory/hosts.yml first)
ansible-playbook -i inventory/hosts.yml roles/k3s_upgrade/

# Restart monitoring services
kubectl rollout restart deployment/prometheus -n monitoring
kubectl rollout restart deployment/grafana -n monitoring

# Check cluster health
kubectl get componentstatuses
kubectl cluster-info
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test thoroughly
4. Update documentation as needed
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details

---

**Happy HomeLab-ing!** 🏠✨
