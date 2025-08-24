# Scripts Directory

Utility scripts for homelab automation and management.

## Available Scripts

### `create-app.sh`
**Application Creation Tool**

Creates new applications from templates with automated placeholder replacement.

#### Usage
```bash
./scripts/create-app.sh <template> <app-name> [options]
```

#### Templates
- `webapp` - Simple stateless web application
- `stateful` - Application with persistent storage
- `stack` - Multi-service stack (frontend + backend + database)

#### Options
- `-i, --image IMAGE` - Docker image name
- `-t, --tag TAG` - Docker image tag (default: latest)
- `-p, --port PORT` - Application port
- `-n, --nodeport PORT` - NodePort for external access
- `-s, --storage SIZE` - Storage size for stateful apps (default: 5Gi)

#### Examples
```bash
# Simple web application
./scripts/create-app.sh webapp whoami -i traefik/whoami -t v1.8 -p 80 -n 30080

# Database with persistent storage
./scripts/create-app.sh stateful postgres -i postgres -t 13 -p 5432 -s 10Gi -n 30432

# Multi-service stack (requires manual configuration)
./scripts/create-app.sh stack todoapp
```

#### Output
- Creates `scripts/generated-apps/<app-name>/` directory
- Generates deployment manifests with proper:
  - Resource limits and requests
  - Health checks (liveness/readiness probes)
  - Security contexts
  - Monitoring annotations
  - Service definitions (ClusterIP + NodePort)
- Creates README.md with deployment instructions

#### Features
- ✅ Placeholder validation and replacement
- ✅ NodePort conflict detection
- ✅ Kubernetes naming convention enforcement
- ✅ Built-in help and error handling
- ✅ Color-coded output
- ✅ App name uniqueness checking

## Adding New Scripts

1. Create executable script:
```bash
touch scripts/new-script.sh
chmod +x scripts/new-script.sh
```

2. Follow conventions:
- Use bash shebang: `#!/bin/bash`
- Set strict mode: `set -e`
- Include usage function
- Use color-coded output functions
- Add to this README

3. Test thoroughly before committing

## Script Conventions

### Output Functions
```bash
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_success() { echo -e "${GREEN}✅${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}❌${NC} $1"; }
```

### Error Handling
- Use `set -e` for exit on error
- Validate inputs early
- Provide clear error messages
- Clean up on failure when needed

### Help and Usage
- Include `usage()` function
- Support `-h|--help` flag
- Show examples in help text
- Document all options and arguments
