
# Agent Orchestration Operations Repository

This repository contains comprehensive operational artifacts for agent orchestration systems, including runbooks, operational gates, monitoring alerts, canary deployment reports, infrastructure configurations, and synchronization frameworks.

## Repository Structure

```
├── runbooks/           # Operational runbooks and procedures
├── gates/             # Operational readiness gates and checklists
├── alerts/            # Monitoring and alerting configurations
├── canary-reports/    # Canary deployment analysis reports
├── sync-framework/    # Cross-system synchronization framework
├── infra/             # Infrastructure as Code (Docker, K8s, Helm)
│   ├── docker/        # Docker Compose configurations
│   ├── k8s/           # Kubernetes manifests (base + overlays)
│   └── helmfile/      # Helm chart configurations
├── tests/             # Integration and smoke tests
├── scripts/           # Operational scripts (deployment, rollback)
└── docs/              # Additional documentation
```

## Quick Start

### Prerequisites

- Docker and Docker Compose (for local development)
- kubectl (for Kubernetes deployments)
- Python 3.11+ (for running tests)
- Access to Kubernetes cluster (for production deployments)

### Local Development - Docker Compose Smoke Test

Run the complete stack locally with Docker Compose:

```bash
# Navigate to Docker infrastructure directory
cd infra/docker

# Start all services (Redis, LiteLLM router, vLLM)
docker compose -f router-vllm-redis.compose.yml up -d

# Wait for services to be healthy (30-60 seconds)
sleep 30

# Verify service health
curl http://localhost:4000/health  # LiteLLM router
curl http://localhost:8000/health  # vLLM inference engine

# View logs
docker compose -f router-vllm-redis.compose.yml logs -f

# Stop services
docker compose -f router-vllm-redis.compose.yml down -v
```

### Kubernetes Deployment

#### Apply Base Configuration

Deploy the base Kubernetes resources:

```bash
# Apply base manifests (namespace, deployments, services)
kubectl apply -k infra/k8s/base

# Verify deployment
kubectl get pods -n primarch-routing
kubectl get svc -n primarch-routing

# Check deployment status
kubectl rollout status deployment/litellm -n primarch-routing
kubectl rollout status deployment/vllm -n primarch-routing
```

#### Deploy to Specific Environment

Deploy with environment-specific overlays:

```bash
# Deploy to dev environment
kubectl apply -k infra/k8s/overlays/dev

# Deploy to production environment
kubectl apply -k infra/k8s/overlays/prod

# Monitor deployment
kubectl get pods -n primarch-routing -w
```

### Integration Tests

Run the integration test suite:

```bash
# Navigate to tests directory
cd tests

# Install test dependencies
pip install pytest requests prometheus-client

# Start test infrastructure
docker compose -f compose.int.yml up -d

# Run all tests
pytest -v

# Run specific test suites
pytest -v test_router_smoke.py      # Smoke tests
pytest -v test_fallbacks.py         # Fallback behavior tests
pytest -v test_cost_ledgers.py      # Cost tracking tests

# Cleanup
docker compose -f compose.int.yml down -v
```

### Canary Deployment Workflow

#### Start Canary Deployment

Deploy a new version with gradual traffic shift:

```bash
# Start canary with 10% traffic
./scripts/canary-start.sh dev 10

# Monitor canary metrics
kubectl get pods -n primarch-routing -l version=canary
kubectl logs -n primarch-routing -l version=canary -f

# Check canary report
cat canary-reports/canary-dev-*.md
```

#### Rollback Canary Deployment

If issues are detected, rollback to stable version:

```bash
# Rollback with reason
./scripts/canary-rollback.sh dev "High error rate detected"

# Verify rollback
kubectl get pods -n primarch-routing
cat DECISIONS.log
```

### Operational Gates

Before deploying to production, validate all operational gates:

```bash
# Review deployment gates checklist
cat gates/deployment-gates.md

# Validate routing metrics
# (In production, query Prometheus/Grafana for actual metrics)

# Check deployment readiness
# - Code review completed
# - Security scan passed
# - Performance tests passed
# - Integration tests passed
# - Canary analysis approved
```

### CI/CD Pipeline

The repository includes a comprehensive ops readiness pipeline:

```yaml
# Workflow: .github/workflows/ops-readiness.yml
# Jobs:
#   1. infra-docker-up: Smoke test with Docker Compose
#   2. routing-gate: Validate metrics and gates
#   3. canary-start: Deploy canary with traffic split
#   4. canary-rollback: Automated rollback on failure
```

Trigger the pipeline:

```bash
# Push to trigger pipeline
git push origin feature/your-branch

# Manual workflow dispatch
gh workflow run ops-readiness.yml -f environment=dev
```

## Day-0 Commands Reference

### Quick Health Check

```bash
# Local Docker Compose
curl http://localhost:4000/health && echo "✓ Router healthy"
curl http://localhost:8000/health && echo "✓ vLLM healthy"

# Kubernetes
kubectl get pods -n primarch-routing
kubectl get svc -n primarch-routing
```

### View Logs

```bash
# Docker Compose
docker compose -f infra/docker/router-vllm-redis.compose.yml logs -f

# Kubernetes
kubectl logs -n primarch-routing -l app=litellm -f
kubectl logs -n primarch-routing -l app=vllm -f
```

### Monitoring and Metrics

```bash
# Check Prometheus metrics (if configured)
curl http://localhost:4000/metrics

# View canary reports
ls -la canary-reports/

# Check deployment decisions log
cat DECISIONS.log
```

## Usage

### Runbooks
Navigate to `runbooks/` for step-by-step operational procedures covering incident response, deployment, and maintenance tasks.

### Gates
Check `gates/` for deployment and operational readiness criteria. All gates must be validated before production deployments.

### Alerts
Review `alerts/` for monitoring and alerting configurations. Integrate with your observability platform (Prometheus, Grafana, etc.).

### Canary Reports
Examine `canary-reports/` for deployment analysis and decision logs. Each canary deployment generates a detailed report.

### Sync Framework
Explore `sync-framework/` for system synchronization tools and cross-repository coordination.

## Production Readiness Checklist

- [x] Infrastructure as Code (Docker, K8s, Helm)
- [x] Integration test suite
- [x] Deployment gates and validation
- [x] Canary deployment workflow
- [x] Automated rollback procedures
- [x] Monitoring and alerting
- [x] Decision logging (DECISIONS.log)
- [x] CI/CD pipeline (ops-readiness.yml)

## Contributing

1. Create a feature branch from `ops-readiness`
2. Make your changes
3. Run integration tests locally
4. Submit a pull request
5. Ensure CI pipeline passes

## Support

For operational issues or questions:
- Review runbooks in `runbooks/`
- Check deployment gates in `gates/`
- Consult canary reports in `canary-reports/`
- Review decision logs in `DECISIONS.log`

---

**Production Ready**: This repository provides a complete operational framework for deploying and managing agent orchestration systems with confidence.
