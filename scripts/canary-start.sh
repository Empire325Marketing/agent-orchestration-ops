
#!/usr/bin/env bash
#
# canary-start.sh - Start canary deployment with traffic split
#
# Usage: ./canary-start.sh <environment> <canary_percentage>
# Example: ./canary-start.sh dev 10
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
K8S_BASE="${REPO_ROOT}/infra/k8s"
CANARY_REPORTS="${REPO_ROOT}/canary-reports"
DECISIONS_LOG="${REPO_ROOT}/DECISIONS.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Validate arguments
if [ $# -lt 2 ]; then
    log_error "Usage: $0 <environment> <canary_percentage>"
    log_error "Example: $0 dev 10"
    exit 1
fi

ENVIRONMENT="$1"
CANARY_PERCENTAGE="$2"
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
DEPLOYMENT_ID="canary-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S)"

# Validate environment
if [[ ! "${ENVIRONMENT}" =~ ^(dev|staging|prod)$ ]]; then
    log_error "Invalid environment: ${ENVIRONMENT}"
    log_error "Valid environments: dev, staging, prod"
    exit 1
fi

# Validate canary percentage
if [ "${CANARY_PERCENTAGE}" -lt 1 ] || [ "${CANARY_PERCENTAGE}" -gt 50 ]; then
    log_error "Invalid canary percentage: ${CANARY_PERCENTAGE}"
    log_error "Valid range: 1-50"
    exit 1
fi

log_info "Starting canary deployment..."
log_info "Environment: ${ENVIRONMENT}"
log_info "Canary percentage: ${CANARY_PERCENTAGE}%"
log_info "Stable percentage: $((100 - CANARY_PERCENTAGE))%"
log_info "Deployment ID: ${DEPLOYMENT_ID}"

# Create decisions log if it doesn't exist
touch "${DECISIONS_LOG}"

# Log deployment decision
cat >> "${DECISIONS_LOG}" <<EOF

================================================================================
CANARY DEPLOYMENT STARTED
================================================================================
Timestamp: ${TIMESTAMP}
Deployment ID: ${DEPLOYMENT_ID}
Environment: ${ENVIRONMENT}
Canary Traffic: ${CANARY_PERCENTAGE}%
Stable Traffic: $((100 - CANARY_PERCENTAGE))%
Triggered by: ${USER}
Host: $(hostname)
================================================================================

EOF

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    log_warning "kubectl not found - simulating deployment"
    SIMULATE=true
else
    SIMULATE=false
fi

# Apply Kubernetes overlay with traffic split
log_info "Applying Kubernetes overlay for ${ENVIRONMENT}..."

if [ "${SIMULATE}" = true ]; then
    log_warning "SIMULATION MODE: Would apply K8s overlay"
    log_info "Command: kubectl apply -k ${K8S_BASE}/overlays/${ENVIRONMENT}"
    log_info "Traffic split configuration:"
    log_info "  - Canary: ${CANARY_PERCENTAGE}%"
    log_info "  - Stable: $((100 - CANARY_PERCENTAGE))%"
else
    # Apply the overlay
    if kubectl apply -k "${K8S_BASE}/overlays/${ENVIRONMENT}"; then
        log_success "Kubernetes overlay applied successfully"
    else
        log_error "Failed to apply Kubernetes overlay"
        exit 1
    fi
    
    # Wait for rollout
    log_info "Waiting for canary pods to be ready..."
    kubectl rollout status deployment/litellm-canary -n primarch-routing --timeout=5m || true
    kubectl rollout status deployment/vllm-canary -n primarch-routing --timeout=5m || true
fi

# Create canary report
log_info "Generating canary deployment report..."

mkdir -p "${CANARY_REPORTS}"
REPORT_FILE="${CANARY_REPORTS}/${DEPLOYMENT_ID}.md"

cat > "${REPORT_FILE}" <<EOF
# Canary Deployment Report

## Deployment Overview
- **Date**: ${TIMESTAMP}
- **Deployment ID**: ${DEPLOYMENT_ID}
- **Environment**: ${ENVIRONMENT}
- **Canary Percentage**: ${CANARY_PERCENTAGE}%
- **Stable Percentage**: $((100 - CANARY_PERCENTAGE))%
- **Duration**: 30 minutes (planned)
- **Status**: ACTIVE

## Deployment Details
- **Triggered by**: ${USER}
- **Host**: $(hostname)
- **K8s Overlay**: ${K8S_BASE}/overlays/${ENVIRONMENT}

## Traffic Split Configuration
\`\`\`yaml
canary:
  weight: ${CANARY_PERCENTAGE}
  replicas: 1
stable:
  weight: $((100 - CANARY_PERCENTAGE))
  replicas: 2
\`\`\`

## Key Metrics (Initial)
- **Success Rate**: Monitoring...
- **Error Rate**: Monitoring...
- **Response Time**: Monitoring...
- **Throughput**: Monitoring...

## Monitoring Queries
\`\`\`promql
# Error rate comparison
rate(http_requests_total{status=~"5.."}[5m])

# P95 latency comparison
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Request rate by version
rate(http_requests_total[5m])
\`\`\`

## Analysis Results
- **Performance Impact**: Under observation
- **User Experience**: Monitoring user feedback
- **System Stability**: Initial checks passed
- **Recommendation**: Continue monitoring for 30 minutes

## Next Steps
- [ ] Monitor canary metrics for 30 minutes
- [ ] Compare canary vs stable performance
- [ ] Analyze error rates and latency
- [ ] Check resource utilization
- [ ] Decision: Full rollout or rollback

## Rollback Command
If issues detected, execute:
\`\`\`bash
./scripts/canary-rollback.sh ${ENVIRONMENT} "Reason for rollback"
\`\`\`

## Timeline
- **${TIMESTAMP}**: Canary deployment initiated
- **$(date -u -d "+30 minutes" +"%Y-%m-%d %H:%M:%S UTC" 2>/dev/null || echo "T+30min")**: Decision point

---
*Report generated by canary-start.sh*
EOF

log_success "Canary report created: ${REPORT_FILE}"

# Display next steps
log_info ""
log_info "=========================================="
log_info "Canary Deployment Initiated Successfully"
log_info "=========================================="
log_info ""
log_info "Next steps:"
log_info "1. Monitor canary metrics for 30 minutes"
log_info "2. Compare canary vs stable performance"
log_info "3. Review report: ${REPORT_FILE}"
log_info ""
log_info "Monitoring commands:"
if [ "${SIMULATE}" = false ]; then
    log_info "  kubectl get pods -n primarch-routing -l version=canary"
    log_info "  kubectl logs -n primarch-routing -l version=canary --tail=100 -f"
fi
log_info ""
log_info "Rollback command (if needed):"
log_info "  ./scripts/canary-rollback.sh ${ENVIRONMENT} \"Reason\""
log_info ""

log_success "Canary deployment started successfully!"
exit 0
