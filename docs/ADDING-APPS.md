# Adding New Applications to K3s Homelab

Complete guide for deploying new services, stacks, and applications to your K3s homelab cluster.

## 🎯 Overview

This guide covers different methods to add applications to your cluster, from simple single-container apps to complex multi-service stacks.

## 📁 Organization Structure

### Recommended Directory Layout

```
manifests/
├── core/                    # Core cluster services
│   ├── monitoring/         # Monitoring stack
│   ├── ingress/           # Ingress controllers
│   └── storage/           # Storage classes, PVs
├── apps/                   # User applications
│   ├── nextcloud/         # File sharing
│   ├── homeassistant/     # Home automation
│   ├── plex/              # Media server
│   └── grafana/           # Additional Grafana
├── services/               # Supporting services
│   ├── databases/         # PostgreSQL, MySQL, Redis
│   ├── messaging/         # RabbitMQ, NATS
│   └── proxy/             # Reverse proxies
└── experiments/            # Testing new apps
    └── temp-apps/
```

### Namespace Strategy

```yaml
# Core services
monitoring: monitoring
ingress-nginx: ingress-system
cert-manager: cert-manager

# Applications by category
media: media-apps
productivity: productivity-apps
development: dev-tools
home-automation: home-auto

# Per-application (for complex stacks)
nextcloud: nextcloud
gitlab: gitlab
```

## 🚀 Deployment Methods

### Method 1: Direct kubectl (Simple Apps)

**Best for**: Single-container applications, quick testing

```bash
# 1. Create namespace
kubectl create namespace my-app

# 2. Apply manifests
kubectl apply -f manifests/apps/my-app/

# 3. Verify deployment
kubectl get pods -n my-app
```

**Example**: Simple web application

```yaml
# manifests/apps/whoami/namespace.yml
---
apiVersion: v1
kind: Namespace
metadata:
  name: whoami
  labels:
    name: whoami
```

```yaml
# manifests/apps/whoami/deployment.yml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whoami
  namespace: whoami
  labels:
    app: whoami
spec:
  replicas: 2
  selector:
    matchLabels:
      app: whoami
  template:
    metadata:
      labels:
        app: whoami
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "80"
    spec:
      containers:
      - name: whoami
        image: traefik/whoami:v1.8
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 10m
            memory: 16Mi
          limits:
            cpu: 100m
            memory: 64Mi
---
apiVersion: v1
kind: Service
metadata:
  name: whoami
  namespace: whoami
  labels:
    app: whoami
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "80"
spec:
  selector:
    app: whoami
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: whoami-nodeport
  namespace: whoami
  labels:
    app: whoami
spec:
  selector:
    app: whoami
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

### Method 2: Helm Charts (Complex Apps)

**Best for**: Popular applications with existing Helm charts

```bash
# 1. Add Helm repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# 2. Create values file
cat > values-nextcloud.yml <<EOF
nextcloud:
  username: admin
  password: "supersecret"

persistence:
  enabled: true
  size: 50Gi

postgresql:
  enabled: true
  auth:
    username: nextcloud
    password: "dbpassword"
    database: nextcloud

ingress:
  enabled: true
  hostname: nextcloud.homelab.local
  annotations:
    kubernetes.io/ingress.class: nginx
EOF

# 3. Install
helm install nextcloud bitnami/nextcloud -n nextcloud --create-namespace -f values-nextcloud.yml

# 4. Check status
helm status nextcloud -n nextcloud
```

### Method 3: Kustomize (Customized Deployments)

**Best for**: Applications requiring environment-specific customization

```bash
# manifests/apps/media-server/base/kustomization.yml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - namespace.yml
  - plex-deployment.yml
  - sonarr-deployment.yml
  - radarr-deployment.yml
  - services.yml

commonLabels:
  stack: media-server
```

```bash
# manifests/apps/media-server/overlays/production/kustomization.yml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../base

patchesStrategicMerge:
  - replica-count.yml
  - resource-limits.yml

configMapGenerator:
  - name: media-config
    files:
      - config.json
```

```bash
# Deploy with kustomize
kubectl apply -k manifests/apps/media-server/overlays/production/
```

### Method 4: Ansible Automation (Repeatable Deployments)

**Best for**: Production deployments, infrastructure as code

```yaml
# roles/homeassistant/tasks/main.yml
---
- name: Create Home Assistant namespace
  shell: kubectl create namespace homeassistant --dry-run=client -o yaml | kubectl apply -f -

- name: Apply Home Assistant manifests
  shell: kubectl apply -f /tmp/homeassistant-manifests/

- name: Wait for Home Assistant to be ready
  shell: kubectl rollout status deployment/homeassistant -n homeassistant --timeout=300s
```

```yaml
# playbooks/homeassistant.yml
---
- name: Deploy Home Assistant
  hosts: server[0]
  gather_facts: true
  become: true
  vars:
    kubeconfig_path: "/etc/rancher/k3s/k3s.yaml"
  roles:
    - role: homeassistant
```

## 🔧 Application Templates

### Template 1: Stateless Web Application

```yaml
# manifests/apps/webapp-template/
---
apiVersion: v1
kind: Namespace
metadata:
  name: APPNAME
  labels:
    name: APPNAME

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: APPNAME
  namespace: APPNAME
  labels:
    app: APPNAME
spec:
  replicas: 2
  selector:
    matchLabels:
      app: APPNAME
  template:
    metadata:
      labels:
        app: APPNAME
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "PORT"
    spec:
      containers:
      - name: APPNAME
        image: IMAGE:TAG
        ports:
        - containerPort: PORT
        env:
        - name: ENV_VAR
          value: "value"
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 256Mi
        livenessProbe:
          httpGet:
            path: /health
            port: PORT
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: PORT
          initialDelaySeconds: 5
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: APPNAME
  namespace: APPNAME
  labels:
    app: APPNAME
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "PORT"
spec:
  selector:
    app: APPNAME
  type: ClusterIP
  ports:
  - port: 80
    targetPort: PORT

---
apiVersion: v1
kind: Service
metadata:
  name: APPNAME-nodeport
  namespace: APPNAME
spec:
  selector:
    app: APPNAME
  type: NodePort
  ports:
  - port: 80
    targetPort: PORT
    nodePort: 30XXX
```

### Template 2: Stateful Application with Persistent Storage

```yaml
# manifests/apps/database-template/
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: APPNAME-data
  namespace: APPNAME
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: APPNAME
  namespace: APPNAME
spec:
  serviceName: APPNAME
  replicas: 1
  selector:
    matchLabels:
      app: APPNAME
  template:
    metadata:
      labels:
        app: APPNAME
    spec:
      containers:
      - name: APPNAME
        image: IMAGE:TAG
        ports:
        - containerPort: PORT
        env:
        - name: DATA_DIR
          value: /data
        volumeMounts:
        - name: data
          mountPath: /data
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

### Template 3: Multi-Service Stack

```yaml
# manifests/apps/stack-template/wordpress.yml
---
apiVersion: v1
kind: Namespace
metadata:
  name: wordpress

---
# MySQL Database
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: wordpress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "rootpassword"
        - name: MYSQL_DATABASE
          value: "wordpress"
        - name: MYSQL_USER
          value: "wordpress"
        - name: MYSQL_PASSWORD
          value: "wppassword"
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: mysql-data
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-data
        emptyDir: {}

---
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: wordpress
spec:
  selector:
    app: mysql
  ports:
  - port: 3306

---
# WordPress Application
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  namespace: wordpress
spec:
  replicas: 2
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
      - name: wordpress
        image: wordpress:php8.1-apache
        env:
        - name: WORDPRESS_DB_HOST
          value: "mysql:3306"
        - name: WORDPRESS_DB_NAME
          value: "wordpress"
        - name: WORDPRESS_DB_USER
          value: "wordpress"
        - name: WORDPRESS_DB_PASSWORD
          value: "wppassword"
        ports:
        - containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: wordpress
  namespace: wordpress
spec:
  selector:
    app: wordpress
  type: NodePort
  ports:
  - port: 80
    nodePort: 30090
```

## 🔍 Integrating with Monitoring

### Add Prometheus Monitoring

```yaml
# Add to your service metadata
metadata:
  annotations:
    prometheus.io/scrape: "true"    # Enable scraping
    prometheus.io/port: "8080"      # Metrics port
    prometheus.io/path: "/metrics"  # Metrics endpoint (default)
```

### Custom ServiceMonitor

```yaml
# manifests/apps/myapp/servicemonitor.yml
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: myapp
  namespace: monitoring
  labels:
    app: myapp
spec:
  selector:
    matchLabels:
      app: myapp
  endpoints:
  - port: http
    interval: 30s
    path: /metrics
```

### Add Logging Labels

```yaml
# Add to pod template
metadata:
  labels:
    app: myapp
    version: v1.0.0
    component: backend
```

### Custom Alerts

```yaml
# Add to prometheus-config.yml
- name: myapp
  rules:
  - alert: MyAppDown
    expr: up{job="myapp"} == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "MyApp is down"
      description: "MyApp has been down for more than 5 minutes"

  - alert: MyAppHighLatency
    expr: http_request_duration_seconds{job="myapp"} > 2
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "MyApp high latency"
      description: "MyApp response time is above 2 seconds"
```

## 💾 Storage Considerations

### Storage Classes

```bash
# Check available storage classes
kubectl get storageclass

# Default K3s storage class
kubectl get storageclass local-path -o yaml
```

### Persistent Volumes

```yaml
# For applications requiring persistence
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myapp-data
  namespace: myapp
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: local-path
```

### Host Path Volumes (For Homelab)

```yaml
# For accessing host directories
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fileserver
spec:
  template:
    spec:
      containers:
      - name: fileserver
        image: nginx
        volumeMounts:
        - name: media-storage
          mountPath: /usr/share/nginx/html
      volumes:
      - name: media-storage
        hostPath:
          path: /mnt/media
          type: Directory
      nodeSelector:
        kubernetes.io/hostname: node-with-storage
```

## 🌐 Networking & Access

### NodePort Services

```yaml
# External access via NodePort
---
apiVersion: v1
kind: Service
metadata:
  name: myapp-external
spec:
  type: NodePort
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30100  # Access via http://node-ip:30100
```

### Ingress (if you have Ingress Controller)

```yaml
# Install nginx ingress controller first
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
  namespace: myapp
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: myapp.homelab.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp
            port:
              number: 80
```

### Load Balancer (MetalLB for Homelab)

```bash
# Install MetalLB first
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

# Configure IP pool
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: homelab-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.10.1.100-10.10.1.110
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: homelab-l2
  namespace: metallb-system
spec:
  ipAddressPools:
  - homelab-pool
EOF
```

## 🔐 Security Best Practices

### Resource Limits

```yaml
# Always set resource limits
resources:
  requests:
    cpu: 10m
    memory: 16Mi
  limits:
    cpu: 100m
    memory: 128Mi
```

### Security Contexts

```yaml
# Run as non-root user
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
  containers:
  - name: myapp
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      capabilities:
        drop:
        - ALL
```

### Network Policies

```yaml
# Restrict network access
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: myapp-netpol
  namespace: myapp
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

### Secrets Management

```yaml
# Store sensitive data in secrets
---
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secrets
  namespace: myapp
type: Opaque
data:
  username: YWRtaW4=  # base64 encoded
  password: cGFzc3dvcmQ=

---
# Use in deployment
spec:
  containers:
  - name: myapp
    env:
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: myapp-secrets
          key: username
    - name: DB_PASS
      valueFrom:
        secretKeyRef:
          name: myapp-secrets
          key: password
```

## 📋 Deployment Checklist

### Pre-Deployment

- [ ] **Namespace planned** and doesn't conflict
- [ ] **Resource requirements** estimated
- [ ] **Storage needs** identified
- [ ] **Network access** requirements defined
- [ ] **Monitoring strategy** planned
- [ ] **Backup strategy** (if stateful)
- [ ] **Security review** completed

### Deployment

- [ ] **Manifests validated** (`kubectl apply --dry-run=client`)
- [ ] **Resource limits set** appropriately
- [ ] **Health checks configured** (liveness/readiness probes)
- [ ] **Monitoring annotations** added
- [ ] **Labels standardized** for organization
- [ ] **Secrets created** if needed
- [ ] **Storage provisioned** if needed

### Post-Deployment

- [ ] **Pods running** successfully
- [ ] **Services accessible** as expected
- [ ] **Metrics appearing** in Prometheus
- [ ] **Logs flowing** to Loki
- [ ] **Alerts configured** if needed
- [ ] **Documentation updated**
- [ ] **Access tested** from expected clients

## 🛠️ Common Deployment Patterns

### Pattern 1: Development → Production

```bash
# Development namespace
kubectl apply -f manifests/apps/myapp/base/ -n myapp-dev

# Test and validate
kubectl port-forward -n myapp-dev svc/myapp 8080:80

# Production deployment
kubectl apply -f manifests/apps/myapp/overlays/production/ -n myapp-prod
```

### Pattern 2: Blue-Green Deployment

```yaml
# Blue deployment (current)
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-blue
  labels:
    version: blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: blue

# Green deployment (new)
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-green
  labels:
    version: green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: green

# Switch traffic by updating service selector
---
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
    version: green  # Switch from blue to green
```

### Pattern 3: Canary Deployment

```yaml
# Stable version (90% traffic)
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-stable
spec:
  replicas: 9
  selector:
    matchLabels:
      app: myapp
      version: stable

# Canary version (10% traffic)
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
      version: canary

# Service selects both versions
---
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp  # No version selector = both versions
```

## 🔍 Troubleshooting New Deployments

### Common Issues

```bash
# Pod not starting
kubectl describe pod -n myapp <pod-name>
kubectl logs -n myapp <pod-name>

# Service not accessible
kubectl get svc -n myapp
kubectl get endpoints -n myapp

# Resource issues
kubectl top pods -n myapp
kubectl describe nodes

# Network issues
kubectl exec -n myapp <pod-name> -- nslookup kubernetes.default
kubectl exec -n myapp <pod-name> -- wget -qO- http://service-name
```

### Debugging Commands

```bash
# Check pod status
kubectl get pods -n myapp -o wide

# Get pod logs
kubectl logs -n myapp deployment/myapp --follow

# Execute commands in pod
kubectl exec -n myapp -it <pod-name> -- /bin/sh

# Port forward for testing
kubectl port-forward -n myapp svc/myapp 8080:80

# Check resource usage
kubectl top pods -n myapp
kubectl describe deployment -n myapp myapp
```

## 📚 Example Applications

### Media Server Stack

```bash
# Complete Plex + Sonarr + Radarr stack
git clone https://github.com/k8s-at-home/charts
helm repo add k8s-at-home https://k8s-at-home.com/charts/
helm install plex k8s-at-home/plex -n media --create-namespace
```

### Development Tools

```bash
# GitLab CE
helm repo add gitlab https://charts.gitlab.io/
helm install gitlab gitlab/gitlab -n gitlab --create-namespace -f values-gitlab.yml

# JupyterHub
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm install jupyterhub jupyterhub/jupyterhub -n jupyter --create-namespace
```

### Home Automation

```bash
# Home Assistant
kubectl apply -f manifests/apps/homeassistant/
# Node-RED
kubectl apply -f manifests/apps/nodered/
# Mosquitto MQTT
kubectl apply -f manifests/apps/mosquitto/
```

## 🚀 Next Steps

### Infrastructure Expansion

1. **Ingress Controller**: Set up nginx-ingress for HTTP routing
2. **Certificate Management**: Install cert-manager for HTTPS
3. **Storage**: Configure Longhorn for distributed storage
4. **Load Balancing**: Deploy MetalLB for LoadBalancer services
5. **GitOps**: Set up ArgoCD for automated deployments

### Application Ideas

- **Productivity**: Nextcloud, Bitwarden, Bookstack
- **Media**: Plex, Jellyfin, Sonarr, Radarr, Bazarr
- **Development**: GitLab, Jenkins, SonarQube
- **Monitoring**: Uptime Kuma, Netdata, Zabbix
- **Networking**: Pi-hole, Unifi Controller
- **Backup**: Velero, Restic, Duplicati

Remember: Start small, test thoroughly, and gradually build complexity! 🏗️

---

**Happy Deploying!** 🚀✨
