# K3d Development Cluster Setup Guide

This guide explains how to set up and use the K3d local Kubernetes cluster for MathTrail development.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                   Host Machine (Windows/Mac/Linux)       │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌────────────────────────────────────────────────────┐  │
│  │           Docker Desktop / Docker Engine           │  │
│  │                                                    │  │
│  │  ┌──────────────────────────────────────────────┐ │  │
│  │  │     K3d Cluster: mathtrail-dev               │ │  │
│  │  │                                              │ │  │
│  │  │  ┌──────────────┐  ┌─────────────────────┐  │ │  │
│  │  │  │ Control      │  │ Worker Nodes        │  │ │  │
│  │  │  │ Plane        │  │ (2x agents)         │  │ │  │
│  │  │  └──────────────┘  └─────────────────────┘  │ │  │
│  │  │                                              │ │  │
│  │  │  ┌──────────────┐  ┌─────────────────────┐  │ │  │
│  │  │  │ Local        │  │ Ingress Controller  │  │ │  │
│  │  │  │ Registry     │  │ (Port 80/443)       │  │ │  │
│  │  │  │ (Port 5000)  │  └─────────────────────┘  │ │  │
│  │  │  └──────────────┘                           │ │  │
│  │  └──────────────────────────────────────────────┘  │
│  └────────────────────────────────────────────────────┘
│                           ▲                            │
│                           │ kubeconfig share           │
│                           │ via ~/.kube/               │
│  ┌────────────────────────┴──────────────────────────┐  │
│  │  DevContainers (with kubectl + helm)             │  │
│  │  • mathtrail-mentor                              │  │
│  │  • mathtrail-ui-web                              │  │
│  │  • mathtrail-infrastructure                      │  │
│  └─────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Step-by-Step Setup

### 1. Install K3d on Host

Navigate to the `mathtrail-infrastructure-local-k3d` directory:

```bash
cd mathtrail-infrastructure-local-k3d
just install
```

This downloads and installs the k3d binary to your system.

### 2. Create the Cluster

```bash
just create
```

This will:
- Create K3d cluster named `mathtrail-dev`
- Start 1 server (control plane) and 2 agent nodes
- Create a local Docker registry at `localhost:5000`
- Configure ingress for HTTP/HTTPS traffic
- Wait for cluster to be ready (~1-2 minutes)

Monitor the process:

```bash
just logs
```

### 3. Extract Kubeconfig

After cluster creation, extract the kubeconfig file:

```bash
just kubeconfig
```

This saves the cluster configuration to `~/.kube/k3d-mathtrail-dev.yaml`.

**Location**: 
- **Linux/macOS**: `~/.kube/k3d-mathtrail-dev.yaml`
- **Windows**: `%USERPROFILE%\.kube\k3d-mathtrail-dev.yaml`

### 4. Verify Cluster Access

Check cluster status from host:

```bash
just status
```

View cluster information:

```bash
kubectl --kubeconfig ~/.kube/k3d-mathtrail-dev.yaml cluster-info
```

## DevContainer Integration

### How It Works

1. **Host** runs K3d cluster with kubeconfig saved to `~/.kube/`
2. **DevContainers** mount the `~/.kube/` directory as read-only
3. **Inside DevContainer**, the `KUBECONFIG` environment variable points to the cluster config
4. **All tools** (kubectl, helm) automatically use the mounted kubeconfig

### Prerequisites

- K3d cluster must be created and running on host
- Kubeconfig must be saved (`just kubeconfig`)
- DevContainer must have kubectl and helm installed (already configured)

### Automatic Connection

When you start a DevContainer, it will automatically:

1. Check if the K3d cluster is accessible
2. Display a status message (✅ or ⚠️)
3. Enable kubectl/helm commands for cluster management

Check connection inside DevContainer:

```bash
# View cluster connection
kubectl cluster-info

# List cluster nodes
kubectl get nodes

# Check helm access
helm version
```

## Deploying Services

### From mathtrail-mentor DevContainer

Deploy the mentor service:

```bash
# Inside DevContainer
cd mathtrail-mentor

# Install/upgrade deployment
helm upgrade --install mathtrail-mentor ./helm/mathtrail-mentor \
    --values ./helm/mathtrail-mentor/values.yaml

# Check deployment status
kubectl rollout status deployment/mathtrail-mentor

# View pods
kubectl get pods -l app=mathtrail-mentor

# View service
kubectl get svc mathtrail-mentor
```

### From mathtrail-infrastructure DevContainer

Deploy infrastructure:

```bash
# Inside DevContainer
cd mathtrail-infrastructure

# Deploy infrastructure
just deploy
```

### Using Local Registry

The K3d cluster includes a built-in registry. Push images from the host and use them in the cluster:

```bash
# Build image locally
docker build -t myservice:1.0 .

# Tag for external registry access (if needed)
docker tag myservice:1.0 localhost:5555/myservice:1.0

# Push to Docker Hub or other registry
docker push myregistry/myservice:1.0

# Inside cluster, use the image URL
# image: myregistry/myservice:1.0
```

For local development without pushing to a registry, you can load images directly into K3d:

```bash
# Build and load image directly into K3d
k3d image load ./Dockerfile --cluster mathtrail-dev -i myservice:1.0
```

## Useful Commands

### View All Available Commands

```bash
cd mathtrail-infrastructure-local-k3d
just help
```

### Cluster Management

```bash
# Start cluster (if stopped)
just start

# Stop cluster (without deleting)
just stop

# Delete cluster completely
just delete

# Check cluster status
just status

# View cluster logs
just logs

# Refresh kubeconfig
just kubeconfig
```

### Kubernetes Operations (from DevContainer)

```bash
# Get all resources
kubectl get all

# Get resources in a namespace
kubectl get pods -n vault

# Describe a resource
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name>

# Port forward to access service
kubectl port-forward svc/mathtrail-mentor 8080:80

# Execute command in pod
kubectl exec -it <pod-name> -- bash

# Apply a manifest
kubectl apply -f deployment.yaml
```

### Helm Operations (from DevContainer)

```bash
# List releases
helm list

# Show release values
helm get values mathtrail-mentor

# Show manifest
helm get manifest mathtrail-mentor

# Uninstall release
helm uninstall mathtrail-mentor

# Dry-run to test deployment
helm install mathtrail-mentor ./helm/mathtrail-mentor --dry-run --debug
```

## Troubleshooting

### Cluster Won't Start

```bash
# Check Docker is running
docker ps

# View error logs
just logs

# Rebuild cluster
just delete
just create
```

### DevContainer Can't Access Cluster

**Problem**: Inside DevContainer, `kubectl cluster-info` fails

**Solutions**:

1. Verify kubeconfig exists on host:
   ```bash
   # On host
   ls ~/.kube/k3d-mathtrail-dev.yaml
   just status
   ```

2. Check KUBECONFIG is set in DevContainer:
   ```bash
   # Inside DevContainer
   echo $KUBECONFIG
   cat $KUBECONFIG
   ```

3. Verify mount is correct:
   ```bash
   # Inside DevContainer
   ls -la /root/.kube/
   ```

4. Restart DevContainer
   - Close DevContainer in VS Code
   - Run "Dev Containers: Rebuild and Reopen in Container"

5. On Windows with WSL2:
   - Ensure Docker Desktop is running with WSL2 backend
   - K3d cluster must be created in native WSL2 environment

### Port Already in Use

If ports 80, 443, or 5000 are already in use:

1. Identify the process:
   ```bash
   # Linux/macOS
   lsof -i :80
   
   # Windows
   netstat -ano | findstr :80
   ```

2. Stop the process or modify K3d port mappings

3. Edit `justfile` constants:
   ```bash
   K3D_PORT_HTTP := "8080:80@loadbalancer"
   K3D_PORT_HTTPS := "8443:443@loadbalancer"
   REGISTRY_PORT := "5001"
   ```

4. Recreate cluster:
   ```bash
   just delete
   just create
   ```

### High Memory/CPU Usage

K3d clusters consume resources. Monitor and optimize:

```bash
# Check Docker resource usage
docker stats

# Reduce cluster resources by editing justfile (not recommended):
# --memory < 2048
# --cpus < 2

# Or stop the cluster when not in use:
just stop
```

### Images Can't Be Found

If deployments fail with image pull errors:

1. Check registry connectivity:
   ```bash
   # From host
   curl http://localhost:5000/v2/_catalog
   ```

2. Verify image is pushed:
   ```bash
   docker push localhost:5000/myapp:latest
   ```

3. Check registry credentials in deployments (usually not needed locally)

## Performance Tips

1. **Stop cluster when not working**:
   ```bash
   just stop
   ```

2. **Use image registry locally** instead of pulling from Docker Hub

3. **Monitor resource usage**:
   ```bash
   docker stats
   ```

4. **Clean up unused images and containers**:
   ```bash
   docker system prune -a
   ```

5. **Use persistent storage** for databases and stateful services

## Next Steps

1. ✅ Cluster is set up and accessible from DevContainers
2. 📦 Deploy services from individual microservice DevContainers
3. 🔄 Set up CI/CD pipelines for automated deployments
4. 📊 Add monitoring and logging to cluster
5. 🛡️ Implement network policies and RBAC

## Additional Resources

- [K3d Documentation](https://k3d.io/)
- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Command Reference](https://kubernetes.io/docs/reference/kubectl/)
- [Helm Documentation](https://helm.sh/docs/)

## Support

For issues or questions:

1. Check logs: `just logs`
2. Review troubleshooting section above
3. Check K3d GitHub issues: https://github.com/k3d-io/k3d/issues
4. Review MathTrail documentation in `/docs`
