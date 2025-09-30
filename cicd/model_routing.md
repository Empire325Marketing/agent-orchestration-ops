# Model Routing CI/CD Configuration

**Chapter 38 - Model Routing & Batching Optimization**

## Overview

This document defines the CI/CD pipeline for model routing configuration changes, including validation, canary deployment, progressive rollout, and automated rollback procedures.

## Configuration Management

### Repository Structure
```
/srv/primarch/routing/
├── litellm_router.yaml          # Main router configuration
├── vllm_config.yaml            # vLLM engine configuration  
├── openai_batch_profiles.yaml  # Batch processing profiles
├── schemas/
│   ├── router_schema.json      # JSON schema for validation
│   ├── vllm_schema.json        # vLLM config validation
│   └── batch_schema.json       # Batch profile validation
└── tests/
    ├── config_validation.py    # Configuration validation tests
    ├── integration_tests.py    # End-to-end integration tests
    └── load_tests/
        ├── canary_test.sh      # Canary traffic validation
        └── stress_test.py      # Load testing scripts
```

### Signed Configuration Requirement
- **All routing configuration files MUST be signed** using GPG keys
- **No plain-text secrets allowed** - only Vault references (`${VAULT:secret/path}`)
- **Configuration drift detection** with automatic alerts
- **Immutable deployments** with full audit trail

### Secret Management
```yaml
# Example Vault reference format in configs
api_key_env: VAULT:secret/primarch/providers/openai/api_key
redis_password_env: VAULT:secret/primarch/infrastructure/redis/password
```

## Pre-Merge Validation Pipeline

### 1. Schema Validation
```bash
#!/bin/bash
# scripts/validate_schemas.sh

echo "🔍 Validating routing configuration schemas..."

# Validate LiteLLM router config
jsonschema -i /srv/primarch/routing/litellm_router.yaml \
           /srv/primarch/routing/schemas/router_schema.json
if [ $? -ne 0 ]; then
  echo "❌ LiteLLM router schema validation FAILED"
  exit 1
fi

# Validate vLLM config
jsonschema -i /srv/primarch/routing/vllm_config.yaml \
           /srv/primarch/routing/schemas/vllm_schema.json
if [ $? -ne 0 ]; then
  echo "❌ vLLM config schema validation FAILED"
  exit 1
fi

# Validate batch profiles
jsonschema -i /srv/primarch/routing/openai_batch_profiles.yaml \
           /srv/primarch/routing/schemas/batch_schema.json
if [ $? -ne 0 ]; then
  echo "❌ Batch profiles schema validation FAILED"
  exit 1
fi

echo "✅ All schema validations PASSED"
```

### 2. Configuration Dry-Run Validation
```bash
#!/bin/bash
# scripts/dry_run_validation.sh

echo "🧪 Running configuration dry-run validation..."

# Test LiteLLM config parsing
docker run --rm -v /srv/primarch/routing:/config \
  litellm/litellm:latest \
  --config /config/litellm_router.yaml \
  --test-config-only
if [ $? -ne 0 ]; then
  echo "❌ LiteLLM config dry-run FAILED"
  exit 1
fi

# Test vLLM config validation
python3 /srv/primarch/routing/tests/validate_vllm_config.py \
  --config /srv/primarch/routing/vllm_config.yaml \
  --dry-run
if [ $? -ne 0 ]; then
  echo "❌ vLLM config validation FAILED"
  exit 1
fi

# Validate batch profile logic
python3 /srv/primarch/routing/tests/validate_batch_profiles.py \
  --config /srv/primarch/routing/openai_batch_profiles.yaml \
  --check-quotas --check-permissions
if [ $? -ne 0 ]; then
  echo "❌ Batch profiles validation FAILED"
  exit 1
fi

echo "✅ All dry-run validations PASSED"
```

### 3. Risk Assessment
```python
#!/usr/bin/env python3
# scripts/assess_config_risk.py

import yaml
import sys
from typing import Dict, List

def assess_weight_changes(old_config: Dict, new_config: Dict) -> int:
    """Assess risk of weight changes. Returns risk score 0-10."""
    risk_score = 0
    
    old_weights = old_config.get('weights', {})
    new_weights = new_config.get('weights', {})
    
    for model in new_weights:
        if model not in old_weights:
            risk_score += 2  # New model routing
            continue
            
        for provider, new_weight in new_weights[model].items():
            old_weight = old_weights.get(model, {}).get(provider, 0)
            
            # Large weight changes are risky
            weight_change = abs(new_weight - old_weight)
            if weight_change > 50:
                risk_score += 5
            elif weight_change > 25:
                risk_score += 3
            elif weight_change > 10:
                risk_score += 1
                
            # Complete provider removal is very risky
            if old_weight > 0 and new_weight == 0:
                risk_score += 4
                
    return min(risk_score, 10)

def assess_timeout_changes(old_config: Dict, new_config: Dict) -> int:
    """Assess risk of timeout/limit changes."""
    risk_score = 0
    
    old_routing = old_config.get('routing', {})
    new_routing = new_config.get('routing', {})
    
    # Timeout reductions are risky
    old_timeout = old_routing.get('timeout_s', 30)
    new_timeout = new_routing.get('timeout_s', 30)
    
    if new_timeout < old_timeout * 0.5:
        risk_score += 4
    elif new_timeout < old_timeout * 0.75:
        risk_score += 2
        
    return risk_score

def main():
    if len(sys.argv) != 3:
        print("Usage: assess_config_risk.py <old_config.yaml> <new_config.yaml>")
        sys.exit(1)
        
    with open(sys.argv[1]) as f:
        old_config = yaml.safe_load(f)
    with open(sys.argv[2]) as f:
        new_config = yaml.safe_load(f)
        
    total_risk = 0
    total_risk += assess_weight_changes(old_config, new_config)
    total_risk += assess_timeout_changes(old_config, new_config)
    
    print(f"Configuration risk score: {total_risk}/10")
    
    if total_risk >= 8:
        print("❌ HIGH RISK - Manual review required")
        sys.exit(1)
    elif total_risk >= 5:
        print("⚠️  MEDIUM RISK - Extended canary required")
        sys.exit(2)
    else:
        print("✅ LOW RISK - Standard deployment approved")
        
if __name__ == "__main__":
    main()
```

### 4. Integration Testing
```python
#!/usr/bin/env python3
# routing/tests/integration_tests.py

import asyncio
import aiohttp
import pytest
from typing import List, Dict

class RoutingIntegrationTests:
    def __init__(self, base_url: str):
        self.base_url = base_url
        
    async def test_provider_health(self) -> Dict[str, bool]:
        """Test all configured providers respond to health checks."""
        results = {}
        
        async with aiohttp.ClientSession() as session:
            # Test main router health
            async with session.get(f"{self.base_url}/health") as resp:
                results["router"] = resp.status == 200
                
            # Test each provider endpoint
            providers = ["openai", "azure", "anthropic", "vllm"]
            for provider in providers:
                try:
                    async with session.get(f"{self.base_url}/health/{provider}") as resp:
                        results[provider] = resp.status == 200
                except:
                    results[provider] = False
                    
        return results
    
    async def test_routing_logic(self) -> bool:
        """Test routing decisions match configured weights."""
        test_requests = []
        for i in range(100):
            test_requests.append({
                "model": "gpt-4-turbo",
                "messages": [{"role": "user", "content": f"Test message {i}"}],
                "max_tokens": 10
            })
            
        provider_counts = {}
        async with aiohttp.ClientSession() as session:
            for req in test_requests:
                async with session.post(f"{self.base_url}/chat/completions", 
                                      json=req,
                                      headers={"X-Debug-Mode": "true"}) as resp:
                    debug_headers = resp.headers
                    provider = debug_headers.get("X-Routed-Provider", "unknown")
                    provider_counts[provider] = provider_counts.get(provider, 0) + 1
                    
        # Validate distribution matches expected weights (within 20% tolerance)
        expected_weights = {"openai": 60, "azure": 25, "anthropic": 15}
        for provider, expected_pct in expected_weights.items():
            actual_pct = (provider_counts.get(provider, 0) / 100) * 100
            if abs(actual_pct - expected_pct) > 20:
                return False
                
        return True
        
    async def test_fallback_behavior(self) -> bool:
        """Test fallback routing works when primary provider fails."""
        # Simulate primary provider failure
        async with aiohttp.ClientSession() as session:
            # Force failure of OpenAI provider
            await session.post(f"{self.base_url}/admin/providers/openai/disable")
            
            # Test request should fallback to Azure/Anthropic
            test_req = {
                "model": "gpt-4-turbo",
                "messages": [{"role": "user", "content": "Fallback test"}],
                "max_tokens": 10
            }
            
            async with session.post(f"{self.base_url}/chat/completions", 
                                  json=test_req,
                                  headers={"X-Debug-Mode": "true"}) as resp:
                provider = resp.headers.get("X-Routed-Provider")
                is_fallback = resp.headers.get("X-Is-Fallback") == "true"
                
            # Re-enable OpenAI
            await session.post(f"{self.base_url}/admin/providers/openai/enable")
            
            return provider in ["azure", "anthropic"] and is_fallback

async def run_integration_tests():
    """Run all integration tests."""
    tests = RoutingIntegrationTests("http://localhost:8080")
    
    print("🧪 Running routing integration tests...")
    
    # Test provider health
    health_results = await tests.test_provider_health()
    if not all(health_results.values()):
        print(f"❌ Health check failures: {health_results}")
        return False
        
    # Test routing logic  
    if not await tests.test_routing_logic():
        print("❌ Routing logic test FAILED")
        return False
        
    # Test fallback behavior
    if not await tests.test_fallback_behavior():
        print("❌ Fallback behavior test FAILED") 
        return False
        
    print("✅ All integration tests PASSED")
    return True

if __name__ == "__main__":
    success = asyncio.run(run_integration_tests())
    sys.exit(0 if success else 1)
```

## Post-Merge Canary Deployment

### Canary Traffic Progression
```bash
#!/bin/bash
# scripts/canary_deployment.sh

CANARY_STAGES=(10 25 50 100)
CANARY_DURATION_MINUTES=15
ROLLBACK_THRESHOLD_ERROR_RATE=1.5  # 1.5x baseline error rate triggers rollback
ROLLBACK_THRESHOLD_LATENCY=20      # 20% latency increase triggers rollback

echo "🚀 Starting canary deployment for routing configuration..."

# Get baseline metrics
BASELINE_ERROR_RATE=$(prometheus-cli query 'sum(rate(router_errors_total[10m])) / sum(rate(router_requests_total[10m]))' | jq -r '.data.result[0].value[1]')
BASELINE_P95_LATENCY=$(prometheus-cli query 'histogram_quantile(0.95, sum(rate(router_latency_seconds_bucket[10m])) by (le))' | jq -r '.data.result[0].value[1]')

echo "📊 Baseline metrics:"
echo "   Error rate: $(echo $BASELINE_ERROR_RATE | awk '{printf "%.4f%%", $1*100}')"
echo "   P95 latency: $(echo $BASELINE_P95_LATENCY | awk '{printf "%.0f ms", $1*1000}')"

for stage in "${CANARY_STAGES[@]}"; do
  echo ""
  echo "📈 Deploying canary at ${stage}% traffic..."
  
  # Update routing weights for canary
  kubectl patch configmap litellm-config -n primarch --patch "
  data:
    canary_traffic_pct: '${stage}'
  "
  
  # Apply configuration
  kubectl rollout restart deployment/litellm-router -n primarch
  kubectl rollout status deployment/litellm-router -n primarch --timeout=300s
  
  echo "⏱️  Monitoring canary for ${CANARY_DURATION_MINUTES} minutes..."
  
  # Monitor metrics during canary period
  for i in $(seq 1 $CANARY_DURATION_MINUTES); do
    sleep 60
    
    # Check error rate
    CURRENT_ERROR_RATE=$(prometheus-cli query 'sum(rate(router_errors_total[5m])) / sum(rate(router_requests_total[5m]))' | jq -r '.data.result[0].value[1] // 0')
    ERROR_RATE_RATIO=$(echo "$CURRENT_ERROR_RATE / $BASELINE_ERROR_RATE" | bc -l)
    
    # Check latency  
    CURRENT_P95_LATENCY=$(prometheus-cli query 'histogram_quantile(0.95, sum(rate(router_latency_seconds_bucket[5m])) by (le))' | jq -r '.data.result[0].value[1] // 0')
    LATENCY_INCREASE=$(echo "($CURRENT_P95_LATENCY - $BASELINE_P95_LATENCY) / $BASELINE_P95_LATENCY * 100" | bc -l)
    
    echo "   Minute $i: Error rate ratio: $(printf "%.2f" $ERROR_RATE_RATIO)x, Latency change: $(printf "%.1f" $LATENCY_INCREASE)%"
    
    # Check rollback conditions
    if (( $(echo "$ERROR_RATE_RATIO > $ROLLBACK_THRESHOLD_ERROR_RATE" | bc -l) )); then
      echo "❌ ERROR RATE THRESHOLD EXCEEDED - Rolling back!"
      rollback_deployment "error_rate_exceeded"
      exit 1
    fi
    
    if (( $(echo "$LATENCY_INCREASE > $ROLLBACK_THRESHOLD_LATENCY" | bc -l) )); then
      echo "❌ LATENCY THRESHOLD EXCEEDED - Rolling back!"
      rollback_deployment "latency_degradation"
      exit 1
    fi
  done
  
  echo "✅ Canary stage ${stage}% completed successfully"
done

echo ""
echo "🎉 Canary deployment completed successfully at 100% traffic!"

# Append success to decisions log
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | OPERATOR=cicd | CHAPTER=38 | ACTION=canary_deploy_success | CONFIG_HASH=$(git rev-parse HEAD) | BASELINE_ERROR_RATE=$BASELINE_ERROR_RATE | BASELINE_LATENCY_MS=$(echo $BASELINE_P95_LATENCY*1000 | bc)" >> /srv/primarch/DECISIONS.log
```

### Rollback Procedures
```bash
#!/bin/bash
# scripts/rollback_deployment.sh

rollback_deployment() {
  local rollback_reason=$1
  local incident_id=$(uuidgen)
  
  echo "🚨 INITIATING EMERGENCY ROLLBACK - Reason: $rollback_reason"
  echo "🆔 Incident ID: $incident_id"
  
  # Get last known good configuration
  LAST_GOOD_COMMIT=$(git log --oneline --grep="canary_deploy_success" -1 --pretty=format:"%H")
  
  if [ -z "$LAST_GOOD_COMMIT" ]; then
    echo "❌ Cannot find last known good configuration!"
    exit 1
  fi
  
  echo "⏪ Rolling back to commit: $LAST_GOOD_COMMIT"
  
  # Checkout last good config
  git checkout $LAST_GOOD_COMMIT -- /srv/primarch/routing/
  
  # Apply rollback configuration
  kubectl create configmap litellm-config-rollback \
    --from-file=/srv/primarch/routing/litellm_router.yaml \
    -n primarch
    
  kubectl patch deployment litellm-router -n primarch --patch '
  spec:
    template:
      spec:
        volumes:
        - name: config
          configMap:
            name: litellm-config-rollback
  '
  
  # Force restart with rollback config
  kubectl rollout restart deployment/litellm-router -n primarch
  kubectl rollout status deployment/litellm-router -n primarch --timeout=180s
  
  # Wait for metrics to stabilize
  echo "⏱️  Waiting for metrics to stabilize after rollback..."
  sleep 120
  
  # Verify rollback success
  ROLLBACK_ERROR_RATE=$(prometheus-cli query 'sum(rate(router_errors_total[5m])) / sum(rate(router_requests_total[5m]))' | jq -r '.data.result[0].value[1] // 0')
  
  if (( $(echo "$ROLLBACK_ERROR_RATE <= $BASELINE_ERROR_RATE * 1.1" | bc -l) )); then
    echo "✅ Rollback successful - error rate normalized"
  else
    echo "❌ Rollback may have failed - error rate still elevated"
  fi
  
  # Create incident record
  cat > /srv/primarch/reports/rollback_incident_$(date +%Y%m%d_%H%M).md << EOF
# Routing Configuration Rollback - $(date)

## Incident Details
- **Incident ID**: $incident_id
- **Rollback Reason**: $rollback_reason
- **Rollback Time**: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- **Rolled Back To**: $LAST_GOOD_COMMIT
- **Baseline Error Rate**: $(printf "%.6f" $BASELINE_ERROR_RATE)
- **Post-Rollback Error Rate**: $(printf "%.6f" $ROLLBACK_ERROR_RATE)

## Actions Taken
1. Detected SLO violation: $rollback_reason
2. Identified last known good configuration: $LAST_GOOD_COMMIT
3. Applied rollback configuration
4. Restarted routing services
5. Verified metrics stabilization

## Follow-up Actions Required
- [ ] Root cause analysis of failed configuration
- [ ] Review and update canary thresholds if needed
- [ ] Plan re-deployment with fixes
EOF

  # Append rollback to decisions log
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | OPERATOR=cicd | CHAPTER=38 | ACTION=emergency_rollback | REASON=$rollback_reason | INCIDENT_ID=$incident_id | ROLLED_BACK_TO=$LAST_GOOD_COMMIT" >> /srv/primarch/DECISIONS.log
  
  # Send alert to ops team
  curl -X POST https://hooks.slack.com/workflows/... \
    -H 'Content-type: application/json' \
    --data "{
      \"text\": \"🚨 Routing configuration rollback executed\",
      \"attachments\": [{
        \"color\": \"danger\",
        \"fields\": [
          {\"title\": \"Incident ID\", \"value\": \"$incident_id\", \"short\": true},
          {\"title\": \"Reason\", \"value\": \"$rollback_reason\", \"short\": true},
          {\"title\": \"Status\", \"value\": \"Rollback completed\", \"short\": true}
        ]
      }]
    }"
}
```

## Monitoring and Alerting Integration

### Deployment Monitoring Dashboard
```yaml
# grafana/routing_deployment_dashboard.json
dashboard:
  title: "Routing Deployment Monitoring"
  panels:
  - title: "Canary Error Rate"
    query: "sum(rate(router_errors_total[5m])) / sum(rate(router_requests_total[5m]))"
    thresholds:
    - value: 0.01
      color: "yellow"
    - value: 0.02  
      color: "red"
      
  - title: "Canary Latency P95"
    query: "histogram_quantile(0.95, sum(rate(router_latency_seconds_bucket[5m])) by (le))"
    unit: "seconds"
    
  - title: "Provider Traffic Distribution" 
    query: "sum(rate(router_requests_total[5m])) by (provider)"
    visualization: "pie"
    
  - title: "Fallback Rate"
    query: "sum(rate(router_fallback_total[5m])) / sum(rate(router_requests_total[5m]))"
    thresholds:
    - value: 0.05
      color: "yellow"
    - value: 0.10
      color: "red"
```

### Automated Alerting Rules
```yaml
# alertmanager/routing_deployment_alerts.yml
groups:
- name: routing_deployment
  rules:
  - alert: CanaryErrorRateHigh
    expr: |
      (
        sum(rate(router_errors_total[5m])) / sum(rate(router_requests_total[5m]))
      ) > 0.015
    for: 2m
    labels:
      severity: critical
      component: routing
      deployment: canary
    annotations:
      summary: "Canary deployment error rate exceeded threshold"
      description: "Error rate is {{ $value | humanizePercentage }} during canary deployment"
      runbook: "Execute emergency rollback procedure"
      
  - alert: CanaryLatencyDegraded  
    expr: |
      (
        histogram_quantile(0.95, sum(rate(router_latency_seconds_bucket[5m])) by (le)) -
        histogram_quantile(0.95, sum(rate(router_latency_seconds_bucket[5m] offset 1h)) by (le))
      ) / histogram_quantile(0.95, sum(rate(router_latency_seconds_bucket[5m] offset 1h)) by (le)) > 0.20
    for: 5m
    labels:
      severity: warning
      component: routing
      deployment: canary
    annotations:
      summary: "Canary deployment latency degradation detected"
      description: "P95 latency increased by {{ $value | humanizePercentage }} during canary"
      
  - alert: CanaryFallbackExcessive
    expr: |
      sum(rate(router_fallback_total[5m])) / sum(rate(router_requests_total[5m])) > 0.10
    for: 3m
    labels:
      severity: warning
      component: routing 
      deployment: canary
    annotations:
      summary: "Excessive fallback usage during canary deployment"
      description: "Fallback rate is {{ $value | humanizePercentage }} - may indicate provider issues"
```

## Configuration Lifecycle Management

### Version Control and Tagging
```bash
# Tag successful deployments
git tag -a "routing-v1.2.3" -m "Routing config v1.2.3 - Added vLLM local inference"

# Track configuration genealogy
echo "routing-v1.2.3: Added vLLM local inference, adjusted OpenAI weights 60→50%" >> CHANGELOG.md
```

### Environment Promotion Pipeline
```
Development → Staging → Canary (10%) → Production (100%)
     ↓            ↓           ↓              ↓
Schema Valid → Integration → Metrics OK → Full Deploy
```

### Emergency Procedures
- **Break-glass access** for emergency config changes
- **Hot-fix deployment** bypassing canary for P0 incidents  
- **Provider circuit breaker** manual override capability
- **Immediate rollback** capability for any deployment stage

---

**Last Updated**: 2025-09-30 | **Next Review**: 2025-10-30
**Owner**: Platform Engineering | **CI/CD**: GitHub Actions + ArgoCD
