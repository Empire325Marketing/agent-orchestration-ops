#!/usr/bin/env bash
set -euo pipefail

OWNER="Empire325Marketing"
APP_REPO="primarch-platform"
INFRA_REPO="primarch-infra"

has_gh() { command -v gh >/dev/null 2>&1; }

echo "==> Searching for local repos..."
LOCAL=$(ls -d ~/* ~/github_repos/* /srv/* 2>/dev/null | grep -Ei 'primarch.*(platform|core|app)' || true)
if [ -n "${LOCAL:-}" ]; then
  echo "Found local candidate(s):"
  echo "$LOCAL"
fi

if has_gh; then
  echo "==> Checking GitHub for $OWNER/$APP_REPO and $OWNER/$INFRA_REPO"
  gh repo view "$OWNER/$APP_REPO" >/dev/null 2>&1 && APP_EXISTS=1 || APP_EXISTS=0
  gh repo view "$OWNER/$INFRA_REPO" >/dev/null 2>&1 && INFRA_EXISTS=1 || INFRA_EXISTS=0
else
  echo "gh CLI not found; skipping remote check."
  APP_EXISTS=0; INFRA_EXISTS=0
fi

mkdir -p ~/github_repos
cd ~/github_repos

if [ "$APP_EXISTS" = "0" ]; then
  has_gh && gh repo create "$OWNER/$APP_REPO" --private --disable-wiki --disable-issues -y || true
  mkdir -p "$APP_REPO"/{services,agents,packages/{common,telemetry,guardrails},configs,docker,.github/workflows}
  cat > "$APP_REPO/README.md" <<'MD'
# Primarch Platform (Application)
Services:
- /services/orchestrator (FastAPI): /v1/agents, /v1/tasks, /v1/workflows
Agents:
- /agents/{builder,coder,tester,deployer}
Packages:
- /packages/common (pydantic schemas), /telemetry (OTel), /guardrails (LLM-Guard wrappers)
MD
  cat > "$APP_REPO/docker/docker-compose.dev.yml" <<'YML'
version: "3.9"
services:
  redis: { image: redis:7-alpine, ports: ["6379:6379"] }
  orchestrator:
    build: ../services/orchestrator
    env_file: ../configs/dev.env
    ports: ["8080:8080"]
    depends_on: [redis]
YML
  git -C "$APP_REPO" init -b main
  git -C "$APP_REPO" add .
  git -C "$APP_REPO" commit -m "chore: scaffold primarch-platform skeleton"
  has_gh && git -C "$APP_REPO" remote add origin "git@github.com:$OWNER/$APP_REPO.git" || true
  has_gh && git -C "$APP_REPO" push -u origin main || true
fi

if [ "$INFRA_EXISTS" = "0" ]; then
  has_gh && gh repo create "$OWNER/$INFRA_REPO" --private --disable-wiki --disable-issues -y || true
  mkdir -p "$INFRA_REPO"/{terraform/{modules,envs/{dev,prod}},k8s/{base,overlays/{dev,prod}},helm,docs}
  cat > "$INFRA_REPO/README.md" <<'MD'
# Primarch Infra (IaC)
- Terraform: VPC/Networking, K8s/GPU nodes, Postgres+pgvector, Redis, Object storage, Monitoring
- K8s: base + overlays (dev/prod)
- Helm: charts for router (LiteLLM), vLLM, orchestrator, agents
MD
  cat > "$INFRA_REPO/terraform/envs/dev/main.tf" <<'TF'
terraform { required_version = ">= 1.6.0" }
# Add your provider blocks (aws/azurerm/google or on-prem modules) here.
TF
  git -C "$INFRA_REPO" init -b main
  git -C "$INFRA_REPO" add .
  git -C "$INFRA_REPO" commit -m "chore: scaffold primarch-infra skeleton"
  has_gh && git -C "$INFRA_REPO" remote add origin "git@github.com:$OWNER/$INFRA_REPO.git" || true
  has_gh && git -C "$INFRA_REPO" push -u origin main || true
fi

echo "==> Done. Repos prepared. Next: add infra & tests to agent-orchestration-ops."
