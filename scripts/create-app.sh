#!/bin/bash

# K3s Homelab Application Creator
# Creates a new application from templates with placeholder replacement

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "ansible.cfg" ] || [ ! -d "manifests" ]; then
    print_error "Please run this script from the homelab repository root directory"
    exit 1
fi

# Usage function
usage() {
    echo "Usage: $0 <template> <app-name> [options]"
    echo ""
    echo "Templates:"
    echo "  webapp    - Simple stateless web application"
    echo "  stateful  - Application with persistent storage"
    echo "  stack     - Multi-service stack (frontend + backend + database)"
    echo ""
    echo "Options:"
    echo "  -i, --image IMAGE        Docker image name"
    echo "  -t, --tag TAG           Docker image tag (default: latest)"
    echo "  -p, --port PORT         Application port"
    echo "  -n, --nodeport PORT     NodePort for external access"
    echo "  -s, --storage SIZE      Storage size for stateful apps (default: 5Gi)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 webapp whoami -i traefik/whoami -t v1.8 -p 80 -n 30080"
    echo "  $0 stateful postgres -i postgres -t 13 -p 5432 -s 10Gi"
    echo "  $0 stack todoapp -i nginx -t alpine"
}

# Parse command line arguments
TEMPLATE=""
APP_NAME=""
IMAGE=""
TAG="latest"
PORT=""
NODEPORT=""
STORAGE_SIZE="5Gi"

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

TEMPLATE="$1"
APP_NAME="$2"
shift 2

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--image)
            IMAGE="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -n|--nodeport)
            NODEPORT="$2"
            shift 2
            ;;
        -s|--storage)
            STORAGE_SIZE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate inputs
if [ -z "$TEMPLATE" ] || [ -z "$APP_NAME" ]; then
    print_error "Template and app name are required"
    usage
    exit 1
fi

# Validate template
case $TEMPLATE in
    webapp|stateful|stack)
        ;;
    *)
        print_error "Invalid template: $TEMPLATE"
        usage
        exit 1
        ;;
esac

# Validate app name (lowercase, no spaces)
if [[ ! "$APP_NAME" =~ ^[a-z0-9-]+$ ]]; then
    print_error "App name must be lowercase letters, numbers, and hyphens only"
    exit 1
fi

# Check if app directory already exists
APP_DIR="scripts/generated-apps/$APP_NAME"
if [ -d "$APP_DIR" ]; then
    print_error "Application directory $APP_DIR already exists"
    exit 1
fi

# Set defaults based on template
case $TEMPLATE in
    webapp)
        TEMPLATE_FILE="scripts/templates/webapp-template.yml"
        [ -z "$PORT" ] && PORT="80"
        [ -z "$NODEPORT" ] && NODEPORT="30080"
        ;;
    stateful)
        TEMPLATE_FILE="scripts/templates/stateful-template.yml"
        [ -z "$PORT" ] && PORT="5432"
        [ -z "$NODEPORT" ] && NODEPORT="30432"
        ;;
    stack)
        TEMPLATE_FILE="scripts/templates/stack-template.yml"
        # Stack template requires more complex setup
        print_warning "Stack template requires manual configuration after creation"
        ;;
esac

# Validate NodePort range
if [ -n "$NODEPORT" ] && ([ "$NODEPORT" -lt 30000 ] || [ "$NODEPORT" -gt 32767 ]); then
    print_error "NodePort must be in range 30000-32767"
    exit 1
fi

# Check if NodePort is already in use
if [ -n "$NODEPORT" ]; then
    if grep -r "nodePort: $NODEPORT" scripts/generated-apps/ >/dev/null 2>&1; then
        print_warning "NodePort $NODEPORT appears to be already in use"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

print_info "Creating $TEMPLATE application: $APP_NAME"

# Create app directory
mkdir -p "$APP_DIR"

# Copy and customize template
if [ "$TEMPLATE" = "stack" ]; then
    # Stack template needs different handling
    cp "$TEMPLATE_FILE" "$APP_DIR/stack.yml"

    # Basic replacements for stack
    sed -i "s/STACKNAME/$APP_NAME/g" "$APP_DIR/stack.yml"

    print_success "Stack template created at $APP_DIR/stack.yml"
    print_warning "Please manually configure the following in the stack template:"
    echo "  - Frontend image and port"
    echo "  - Backend image and port"
    echo "  - Database image and port"
    echo "  - NodePort numbers"
    echo "  - Environment variables"
else
    # Single service templates
    cp "$TEMPLATE_FILE" "$APP_DIR/deployment.yml"

    # Replace placeholders
    sed -i "s/APPNAME/$APP_NAME/g" "$APP_DIR/deployment.yml"
    [ -n "$IMAGE" ] && sed -i "s|IMAGE|$IMAGE|g" "$APP_DIR/deployment.yml"
    sed -i "s/TAG/$TAG/g" "$APP_DIR/deployment.yml"
    sed -i "s/PORT/$PORT/g" "$APP_DIR/deployment.yml"
    [ -n "$NODEPORT" ] && sed -i "s/30XXX/$NODEPORT/g" "$APP_DIR/deployment.yml"
    sed -i "s/STORAGE_SIZE/$STORAGE_SIZE/g" "$APP_DIR/deployment.yml"

    # For stateful apps, set data path
    if [ "$TEMPLATE" = "stateful" ]; then
        case $IMAGE in
            postgres*)
                sed -i "s|DATA_PATH|/var/lib/postgresql/data|g" "$APP_DIR/deployment.yml"
                ;;
            mysql*)
                sed -i "s|DATA_PATH|/var/lib/mysql|g" "$APP_DIR/deployment.yml"
                ;;
            mongo*)
                sed -i "s|DATA_PATH|/data/db|g" "$APP_DIR/deployment.yml"
                ;;
            redis*)
                sed -i "s|DATA_PATH|/data|g" "$APP_DIR/deployment.yml"
                ;;
            *)
                sed -i "s|DATA_PATH|/data|g" "$APP_DIR/deployment.yml"
                print_warning "Using default data path /data - please verify this is correct"
                ;;
        esac
    fi

    print_success "Application manifests created at $APP_DIR/deployment.yml"
fi

# Create README for the app
cat > "$APP_DIR/README.md" <<EOF
# $APP_NAME

## Configuration

- **Template**: $TEMPLATE
$([ -n "$IMAGE" ] && echo "- **Image**: $IMAGE:$TAG")
$([ -n "$PORT" ] && echo "- **Port**: $PORT")
$([ -n "$NODEPORT" ] && echo "- **NodePort**: $NODEPORT")
$([ "$TEMPLATE" = "stateful" ] && echo "- **Storage**: $STORAGE_SIZE")

## Deployment

\`\`\`bash
# Deploy the application
kubectl apply -f scripts/generated-apps/$APP_NAME/

# Check status
kubectl get pods -n $APP_NAME

# Check logs
kubectl logs -n $APP_NAME deployment/$APP_NAME
\`\`\`

## Access

$([ -n "$NODEPORT" ] && echo "- **External**: http://10.10.1.24:$NODEPORT")
- **Internal**: http://$APP_NAME.$APP_NAME.svc.cluster.local$([ -n "$PORT" ] && [ "$PORT" != "80" ] && echo ":$PORT")

## Monitoring

The application is configured for monitoring with:
- Prometheus metrics scraping
- Log collection via Promtail
- Resource limits and health checks

## Customization

Edit the deployment.yml file to:
- Adjust resource limits
- Add environment variables
- Configure persistent storage
- Update image versions
- Modify health checks

## Cleanup

\`\`\`bash
kubectl delete namespace $APP_NAME
\`\`\`
EOF

print_success "Created README at $APP_DIR/README.md"

# Show summary
print_info "Application created successfully!"
echo ""
echo "📁 Files created:"
echo "   $APP_DIR/"
if [ "$TEMPLATE" = "stack" ]; then
    echo "   ├── stack.yml"
else
    echo "   ├── deployment.yml"
fi
echo "   └── README.md"
echo ""

if [ -n "$IMAGE" ]; then
    echo "🚀 Ready to deploy:"
    echo "   kubectl apply -f $APP_DIR/"
    [ -n "$NODEPORT" ] && echo "   Access: http://10.10.1.24:$NODEPORT"
else
    echo "⚠ Next steps:"
    echo "   1. Edit $APP_DIR/deployment.yml"
    echo "   2. Set the IMAGE placeholder to your Docker image"
    [ "$TEMPLATE" = "stack" ] && echo "   3. Configure all service images and ports"
    echo "   $(([ "$TEMPLATE" = "stack" ] && echo 4 || echo 3)). Deploy: kubectl apply -f $APP_DIR/"
fi

echo ""
echo "📖 See docs/ADDING-APPS.md for detailed documentation"
