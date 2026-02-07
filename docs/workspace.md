# MathTrail Workspace

Instructions for opening mathtrail.code-workspace, connected repositories, and setting up local development environment.

## Prerequisites

### System Requirements

- **Operating System**: Linux, macOS, or Windows (with WSL2 recommended for Windows)
- **Disk Space**: At least 10 GB free space
- **Memory**: 8 GB RAM minimum (16 GB recommended for comfortable development)

### Install on Host Machine

Before cloning the repository, install these tools directly on your computer:

#### 1. Docker

Docker is required for running containers.

- **macOS**: Install [Docker Desktop](https://www.docker.com/products/docker-desktop)
- **Windows**: Install [Docker Desktop](https://www.docker.com/products/docker-desktop) with WSL2 backend
- **Linux**: Follow [official Docker installation guide](https://docs.docker.com/engine/install/)

Verify installation:

```bash
docker --version
```

#### 2. Just

The `just` command runner is required for managing the K3d cluster and running common tasks.

**Recommended installation methods:**

- **Windows**: `choco install just` (Chocolatey) or `cargo install just`
- **macOS**: `brew install just` (Homebrew) or `cargo install just`
- **Linux**: `sudo apt-get install just` (Ubuntu/Debian) or `cargo install just` (any distribution)

Verify installation:

```bash
just --version
```

See [Just Installation Guide](https://github.com/casey/just#installation) for more options.

### Tools Included in DevContainer

The following tools are automatically available when you open this workspace in a DevContainer. **No installation needed:**

- **kubectl** — Kubernetes command-line tool
- **Helm** — Kubernetes package manager
- **Dapr CLI** — Distributed Application Runtime CLI
- **Just** — Task runner for common commands

## Getting Started with MathTrail

### 1. Clone All Repositories

Clone the workspace and all related repositories next to each other:

```bash
cd ~/MathTrail
git clone <URL_REPO>/mathtrail.git
git clone <URL_REPO>/mathtrail-mentor.git
git clone <URL_REPO>/mathtrail-profile.git
git clone <URL_REPO>/mathtrail-task.git
git clone <URL_REPO>/mathtrail-llm-taskgen.git
git clone <URL_REPO>/mathtrail-solution-validator.git
git clone <URL_REPO>/mathtrail-ui-web.git
git clone <URL_REPO>/mathtrail-ui-chatgpt.git
git clone <URL_REPO>/mathtrail-identity.git
git clone <URL_REPO>/mathtrail-infra.git
git clone <URL_REPO>/mathtrail-infra-observability.git
git clone <URL_REPO>/mathtrail-infra-local-k3d.git
git clone <URL_REPO>/mathtrail-charts.git
git clone <URL_REPO>/mathtrail-service-template.git
```

### 2. Open Workspace

Open the workspace in VS Code:

```bash
cd mathtrail
code mathtrail.code-workspace
```

### 3. Set Up Kubernetes Cluster

The project uses **K3d** (K3s in Docker) for local Kubernetes development.

Navigate to the infrastructure-local-k3d directory:

```bash
cd ../mathtrail-infrastructure-local-k3d
just create
just kubeconfig
```

For detailed setup instructions and troubleshooting, see [K3d Setup Guide](k3d-setup.md).

### 4. Deploy Infrastructure

Deploy Dapr and other infrastructure components from the infrastructure DevContainer or using Helm directly.

## Development Environment

### Using DevContainer (Recommended)

A DevContainer is available for each repository:

1. Install the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) in VS Code
2. Click the blue "Dev Container" button in the bottom-left corner of VS Code
3. Select "Reopen in Container"

**Inside the DevContainer, you automatically have:**
- kubectl and Helm for managing the Kubernetes cluster
- Dapr CLI for testing Dapr components
- Just task runner for common commands
- Docker CLI for working with container images
- **Automatic access to K3d cluster** (via kubeconfig mount)

The K3d cluster runs on your host machine. DevContainers connect to it automatically via the mounted kubeconfig file.

## Troubleshooting

### Kubernetes cluster issues

See [K3d Setup Guide - Troubleshooting](k3d-setup.md#troubleshooting) for detailed solutions.

Quick checks:

```bash
# Verify cluster is running (on host)
docker ps | grep k3d

# Check cluster status (on host)
cd ../mathtrail-infrastructure-local-k3d && just status

# Inside DevContainer, verify connection
kubectl cluster-info
kubectl get nodes
```

### DevContainer can't access cluster

1. Verify K3d cluster is created and running on host:
   ```bash
   cd ../mathtrail-infrastructure-local-k3d
   just status
   ```

2. Verify kubeconfig exists:
   ```bash
   ls ~/.kube/k3d-mathtrail-dev.yaml
   ```

3. Restart the DevContainer:
   - Close DevContainer in VS Code
   - Run "Dev Containers: Rebuild and Reopen in Container"
