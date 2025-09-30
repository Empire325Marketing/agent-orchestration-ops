# CI/CD Prompt Policy

## Overview
Continuous integration and deployment policies for prompt firewall rules, persona assets, and safety configurations.

## CI Pipeline Checks

### 1. Configuration Validation
```yaml
# .github/workflows/prompt-validation.yml
name: Prompt Configuration Validation
on:
  pull_request:
    paths:
      - 'safety/promptguard_config.yaml'
      - 'personas/registry.yaml'
      - 'personas/FRANK_*'

jobs:
  validate:
    steps:
      - name: Lint PromptGuard Config
        run: |
          python -m yaml.tool safety/promptguard_config.yaml
          python validate_promptguard_config.py safety/promptguard_config.yaml
      
      - name: Validate Persona Registry
        run: |
          python registry_validator.py personas/registry.yaml
          python asset_checker.py personas/
      
      - name: Check Asset Integrity
        run: |
          cd personas/
          sha256sum -c <(grep SHA256 FRANK_MANIFEST.md | sed 's/.*SHA256**: //')
```

### 2. Safety Test Execution
```yaml
safety_tests:
  steps:
    - name: Run Safety Seed Tests
      run: |
        python safety_tester.py --test-file safety/firewall_tests.txt --config safety/promptguard_config.yaml
    
    - name: Execute Persona Consistency Tests
      run: |
        python persona_tester.py --persona frank --test-suite comprehensive
    
    - name: Validate Firewall Rules
      run: |
        python firewall_rule_tester.py --rules safety/promptguard_config.yaml --samples test_data/
```

### 3. Regression Testing
```yaml
regression_tests:
  steps:
    - name: Compare Against Baseline
      run: |
        python regression_tester.py --baseline baseline_metrics.json --current current_metrics.json
    
    - name: Performance Impact Assessment
      run: |
        python performance_tester.py --config safety/promptguard_config.yaml --baseline performance_baseline.json
```

## Change Approval Requirements

### Automatic Approval (Low Risk)
- Typo fixes in documentation
- Comment updates
- Test data additions
- **Gates**: Linting + basic validation

### Review Required (Medium Risk)
- Firewall rule threshold adjustments
- Persona voice/personality updates
- New safety test patterns
- **Gates**: Full test suite + 1 reviewer approval

### Strict Review (High Risk)  
- Core directive changes
- New firewall detector addition
- Safety policy modifications
- **Gates**: Comprehensive testing + 2 reviewer approval + security team sign-off

## Diff Approval Process

### Persona Asset Changes
```bash
# Generate diff for review
git diff --no-index personas/FRANK_KNOWLEDGE_CORE_old.pdf personas/FRANK_KNOWLEDGE_CORE.pdf > persona_diff.txt

# Structured review
python persona_diff_analyzer.py --old personas/FRANK_KNOWLEDGE_CORE_old.pdf --new personas/FRANK_KNOWLEDGE_CORE.pdf

# Approval workflow
python change_approval.py --change-type persona --reviewer security-team --diff persona_diff.txt
```

### Firewall Rule Changes
```yaml
# Firewall change approval
firewall_change_approval:
  - reviewer_type: "security_engineer"
    required: true
  - reviewer_type: "persona_owner"
    required: true
  - automated_checks:
    - rule_syntax_validation
    - conflict_detection
    - performance_impact_analysis
```

## Failure Conditions

### Hard Failures (Block Deployment)
- Configuration syntax errors
- Safety test failures
- Critical security violations
- Performance regression > 20%
- Asset integrity check failures

### Soft Failures (Warning + Manual Review)
- Minor performance degradation
- Non-critical test failures
- Documentation inconsistencies
- Persona consistency score decline

## Safety Seed Integration (Ch.17)

### Test Execution
```bash
# Run all safety seeds through firewall
python run_safety_seeds.py \
  --seeds safety/firewall_tests.txt \
  --config safety/promptguard_config.yaml \
  --persona frank \
  --output test_results.json

# Validate results
python validate_safety_results.py \
  --results test_results.json \
  --expected expected_blocks.json \
  --threshold 0.99
```

### Expected Outcomes
- All jailbreak attempts blocked (100%)
- All injection patterns detected (100%)
- All data exfiltration blocked (100%)
- All tool abuse prevented (100%)
- All command injection stopped (100%)
- All PII exposure prevented (100%)

### Regression Detection
```python
def check_safety_regression(current_results, baseline_results):
    """Detect if safety effectiveness has regressed."""
    for category in ['jailbreak', 'injection', 'exfiltration', 'tool_abuse']:
        current_rate = current_results[category]['block_rate']
        baseline_rate = baseline_results[category]['block_rate']
        
        if current_rate < baseline_rate - 0.01:  # 1% regression threshold
            raise SafetyRegressionError(f"{category} block rate regressed")
    
    return True
```

## Deployment Gates

### Pre-Production Checklist
- [ ] All CI checks passed
- [ ] Safety seed tests 100% success
- [ ] Performance benchmarks met
- [ ] Persona consistency validated
- [ ] Security review completed
- [ ] Change documentation updated

### Production Deployment
```bash
# Gradual rollout with monitoring
kubectl apply -f prompt-firewall-canary.yaml

# Monitor key metrics
prometheus_query 'prompt_firewall_block_rate[5m]'
prometheus_query 'persona_consistency_score[5m]'

# Auto-rollback on failure
if [[ $(prometheus_query 'safety_violations_total[5m]') -gt 0 ]]; then
  kubectl rollout undo deployment/prompt-firewall
  exit 1
fi
```

### Post-Deployment Validation
```bash
# Comprehensive post-deploy tests
python post_deploy_validator.py \
  --config safety/promptguard_config.yaml \
  --persona frank \
  --duration 1h

# Generate deployment report
python deployment_report.py \
  --deployment-id "$(kubectl get deployment prompt-firewall -o jsonpath='{.metadata.resourceVersion}')" \
  --metrics prometheus_metrics.json \
  --tests post_deploy_results.json
```

## Monitoring Integration

### Key Metrics
- CI pipeline success rate
- Test execution time
- Deployment frequency
- Rollback frequency
- Safety test coverage

### Alerting
```yaml
ci_alerts:
  - name: "CI Pipeline Failures"
    condition: "ci_failure_rate > 0.1"
    severity: "warning"
  
  - name: "Safety Test Regressions"
    condition: "safety_test_failures > 0"
    severity: "critical"
  
  - name: "Deployment Failures"
    condition: "deployment_failure_rate > 0.05"
    severity: "warning"
```

## Documentation Requirements

### Change Documentation
- Clear description of changes made
- Rationale for modifications
- Impact assessment
- Rollback procedures
- Testing performed

### Approval Records
- Reviewer identity and timestamp
- Approval criteria met
- Risk assessment
- Conditions or limitations
- Follow-up requirements

## DECISIONS.log Integration

```
<TIMESTAMP> | OPERATOR=<ci_system> | ACTION=prompt_policy_validation | CHANGE_TYPE=<type> | TESTS=<pass/fail> | REVIEWERS=<count> | DEPLOYMENT=<approved/blocked> | EXECUTOR=<ci_pipeline>
```
