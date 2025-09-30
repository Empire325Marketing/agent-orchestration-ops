# Batch Processing Failure Response Runbook

**Chapter 38 - Model Routing & Batching Optimization**

## Overview

This runbook provides step-by-step procedures for diagnosing and resolving OpenAI Batch API failures, including stuck queues, processing errors, export pipeline issues, and SLA breaches.

## Alert Classification

### P0 - Critical Batch System Failure
- All batch processing stopped >4 hours
- Critical financial/compliance batches failing
- Data loss or corruption in export pipeline

### P1 - Batch Queue Issues
- Queue not draining for >2 hours
- Batch success rate <90% for >1 hour
- SLA breach imminent (<2 hours remaining)

### P2 - Performance Degradation
- Batch processing slower than expected
- Individual batch failures <5%
- Export delays but within SLA

## Incident Response Process

### 1. Immediate Assessment (0-5 minutes)

#### Check Batch System Status
```bash
# Check OpenAI Batch API connectivity
curl -H "Authorization: Bearer $OPENAI_API_KEY" \
     -H "Content-Type: application/json" \
     https://api.openai.com/v1/batches | jq '.object'

# Check internal batch queue status
prometheus-cli query 'openai_batch_queue_depth'
prometheus-cli query 'sum(rate(openai_batch_completed_total[5m])) by (status, profile)'
```

#### Quick Queue Analysis
```bash
# List recent batches by profile
kubectl exec -n primarch deployment/batch-processor -- \
  psql -d primarch -c "
  SELECT profile, status, count(*), max(created_at) 
  FROM batch_jobs 
  WHERE created_at > NOW() - INTERVAL '4 hours'
  GROUP BY profile, status;"

# Check stuck batches
kubectl exec -n primarch deployment/batch-processor -- \
  psql -d primarch -c "
  SELECT batch_id, profile, status, created_at, updated_at,
         NOW() - updated_at as stuck_duration
  FROM batch_jobs 
  WHERE status IN ('submitted', 'in_progress') 
    AND updated_at < NOW() - INTERVAL '2 hours'
  ORDER BY created_at;"
```

#### Verify Dependencies
```bash
# Check export storage connectivity
aws s3 ls s3://$BATCH_EXPORT_BUCKET/openai/batches/ || echo "S3 access FAILED"

# Check batch processor pod health
kubectl get pods -l app=batch-processor -n primarch
kubectl logs -l app=batch-processor -n primarch --tail=50
```

### 2. Immediate Mitigation (5-15 minutes)

#### Identify Failing Batches
```bash
# Get detailed status of recent failed batches
for batch_id in $(kubectl exec -n primarch deployment/batch-processor -- \
  psql -d primarch -t -c "
  SELECT batch_id FROM batch_jobs 
  WHERE status = 'failed' 
    AND created_at > NOW() - INTERVAL '2 hours';"); do
  
  echo "=== Batch: $batch_id ==="
  curl -H "Authorization: Bearer $OPENAI_API_KEY" \
       https://api.openai.com/v1/batches/$batch_id | jq '.errors // .status'
done
```

#### Emergency Queue Management
```bash
# Pause new batch submissions if system overwhelmed
kubectl patch configmap batch-config -n primarch --patch '
data:
  batch_processor.yaml: |
    global_config:
      pause_new_submissions: true
      emergency_mode: true
'

# Restart batch processor to pick up emergency config
kubectl rollout restart deployment/batch-processor -n primarch
```

#### Retry Failed Items
```bash
# Extract failed items from specific batch for retry
batch_id="$FAILED_BATCH_ID"
profile="$BATCH_PROFILE"

# Download failed batch results
curl -H "Authorization: Bearer $OPENAI_API_KEY" \
     https://api.openai.com/v1/batches/$batch_id/output \
     -o /tmp/failed_batch_output.jsonl

# Filter failed items and prepare retry batch
jq -r 'select(.response.status_code != 200) | .custom_id' /tmp/failed_batch_output.jsonl > /tmp/retry_items.txt

# Create retry batch with smaller size
kubectl exec -n primarch deployment/batch-processor -- \
  python3 /app/scripts/retry_batch.py \
    --failed-items /tmp/retry_items.txt \
    --profile $profile \
    --max-items 1000
```

### 3. Root Cause Analysis (15-30 minutes)

#### OpenAI API Status Investigation
```bash
# Check OpenAI system status
curl -s https://status.openai.com/api/v2/status.json | jq '.status.description'

# Analyze batch failure patterns
kubectl exec -n primarch deployment/batch-processor -- \
  psql -d primarch -c "
  SELECT 
    profile,
    error_code,
    error_message,
    count(*) as failure_count,
    avg(extract(epoch from (failed_at - created_at))/3600) as avg_time_to_failure_hours
  FROM batch_jobs 
  WHERE status = 'failed' 
    AND created_at > NOW() - INTERVAL '24 hours'
  GROUP BY profile, error_code, error_message
  ORDER BY failure_count DESC;"
```

#### Batch Size and Rate Limiting Analysis
```bash
# Check if hitting rate limits
prometheus-cli query 'sum(rate(openai_batch_rate_limit_errors_total[1h]))'

# Analyze batch size vs success rate correlation
kubectl exec -n primarch deployment/batch-processor -- \
  psql -d primarch -c "
  SELECT 
    CASE 
      WHEN item_count < 1000 THEN 'small'
      WHEN item_count < 5000 THEN 'medium' 
      WHEN item_count < 20000 THEN 'large'
      ELSE 'xlarge'
    END as batch_size_category,
    count(*) as total_batches,
    sum(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as successful,
    avg(extract(epoch from (completed_at - created_at))/3600) as avg_processing_hours
  FROM batch_jobs 
  WHERE created_at > NOW() - INTERVAL '7 days'
  GROUP BY batch_size_category
  ORDER BY avg_processing_hours;"
```

#### Export Pipeline Issues
```bash
# Check S3 export failures
aws s3api head-bucket --bucket $BATCH_EXPORT_BUCKET || echo "Bucket access issues"

# Check export processing logs
kubectl logs -l app=batch-processor -n primarch --since=2h | grep -E "(export|s3|upload)" | tail -100

# Verify file permissions and sizes
aws s3 ls s3://$BATCH_EXPORT_BUCKET/openai/batches/ --recursive --human-readable | tail -20
```

### 4. Recovery Actions (30-60 minutes)

#### Batch Profile Optimization
```bash
# Switch to smaller batch sizes for failing profiles
kubectl patch configmap batch-config -n primarch --patch '
data:
  openai_batch_profiles.yaml: |
    profiles:
      document_extraction:
        max_batch_items: 10000    # Reduced from 50000
        max_batch_tokens: 1000000 # Reduced from 2000000
        priority: high            # Increase priority
        retry:
          max_attempts: 3         # Increase retries
'
```

#### Queue Processing Strategy
```bash
# Implement priority-based processing
kubectl exec -n primarch deployment/batch-processor -- \
  psql -d primarch -c "
  UPDATE batch_jobs 
  SET priority = 'high' 
  WHERE profile IN ('invoice_processing', 'research_analysis')
    AND status IN ('queued', 'submitted');"

# Process high-priority batches first
kubectl patch configmap batch-config -n primarch --patch '
data:
  queue_management:
    scheduling_algorithm: priority_fifo
    high_priority_boost: 2.0
'
```

#### Alternative Processing Routes
```bash
# Route smaller batches to synchronous API for urgent items
kubectl exec -n primarch deployment/batch-processor -- \
  python3 /app/scripts/emergency_sync_processing.py \
    --profile invoice_processing \
    --max-items 100 \
    --timeout-minutes 30

# Use different model for cost-sensitive processing
kubectl patch configmap batch-config -n primarch --patch '
data:
  profiles:
    document_extraction:
      model: gpt-4o-mini-2024-07-18  # Use more stable model version
'
```

#### Export Pipeline Recovery
```bash
# Clear corrupted export files
aws s3 rm s3://$BATCH_EXPORT_BUCKET/openai/batches/corrupted/ --recursive

# Restart export processing for stuck batches
kubectl exec -n primarch deployment/batch-processor -- \
  python3 /app/scripts/reprocess_exports.py \
    --status completed \
    --missing-export true \
    --max-age-hours 24

# Verify export integrity
kubectl exec -n primarch deployment/batch-processor -- \
  python3 /app/scripts/validate_exports.py \
    --bucket $BATCH_EXPORT_BUCKET \
    --profile all \
    --since 24h
```

### 5. SLA Management and Communication

#### SLA Breach Assessment
```bash
# Calculate SLA breach risk
kubectl exec -n primarch deployment/batch-processor -- \
  psql -d primarch -c "
  SELECT 
    profile,
    batch_id,
    created_at,
    sla_hours,
    extract(epoch from (NOW() - created_at))/3600 as hours_elapsed,
    CASE 
      WHEN extract(epoch from (NOW() - created_at))/3600 > sla_hours THEN 'BREACHED'
      WHEN extract(epoch from (NOW() - created_at))/3600 > sla_hours * 0.8 THEN 'AT_RISK'
      ELSE 'OK'
    END as sla_status
  FROM batch_jobs 
  WHERE status IN ('submitted', 'in_progress', 'queued')
  ORDER BY hours_elapsed DESC;"
```

#### Customer Communication
```bash
# Generate status report for affected tenants
kubectl exec -n primarch deployment/batch-processor -- \
  python3 /app/scripts/generate_status_report.py \
    --incident-id $INCIDENT_ID \
    --affected-profiles "document_extraction,invoice_processing" \
    --output /tmp/customer_status_report.json

# Send notifications to affected customers (if SLA breach >24h)
if [ "$SLA_BREACH_HOURS" -gt 24 ]; then
  kubectl exec -n primarch deployment/batch-processor -- \
    python3 /app/scripts/notify_customers.py \
      --incident-id $INCIDENT_ID \
      --breach-level P1 \
      --estimated-recovery-hours 6
fi
```

### 6. Documentation and Follow-up

#### Cost Attribution and Credits
```bash
# Calculate cost impact for failed/delayed batches
kubectl exec -n primarch deployment/batch-processor -- \
  psql -d primarch -c "
  SELECT 
    profile,
    tenant_id,
    sum(estimated_cost_usd) as total_cost,
    sum(CASE WHEN status = 'failed' THEN estimated_cost_usd ELSE 0 END) as failed_cost,
    count(*) as total_batches,
    sum(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed_batches
  FROM batch_jobs 
  WHERE created_at > NOW() - INTERVAL '24 hours'
    AND incident_id = '$INCIDENT_ID'
  GROUP BY profile, tenant_id;"

# Process credits for SLA breaches (if applicable)
if [ "$SLA_CREDITS_REQUIRED" = "true" ]; then
  kubectl exec -n primarch deployment/batch-processor -- \
    python3 /app/scripts/process_sla_credits.py \
      --incident-id $INCIDENT_ID \
      --breach-type batch_delay \
      --credit-percentage 25
fi
```

#### Incident Documentation
```bash
# Append to decisions log
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | OPERATOR=$USER | CHAPTER=38 | ACTION=resolve_batch_failure | INCIDENT=$INCIDENT_ID | CAUSE=$ROOT_CAUSE | BATCHES_AFFECTED=$AFFECTED_COUNT | SLA_BREACH=$SLA_BREACH_STATUS" >> /srv/primarch/DECISIONS.log

# Create detailed incident report
cat > /srv/primarch/reports/batch_incident_$(date +%Y%m%d_%H%M).md << EOF
# Batch Processing Incident Report - $(date)

## Summary
- **Incident ID**: $INCIDENT_ID
- **Start Time**: $INCIDENT_START
- **End Time**: $INCIDENT_END
- **Affected Profiles**: $AFFECTED_PROFILES
- **Batches Affected**: $AFFECTED_BATCH_COUNT
- **SLA Status**: $SLA_BREACH_STATUS

## Root Cause
$ROOT_CAUSE_ANALYSIS

## Recovery Actions
$RECOVERY_ACTIONS

## Customer Impact
$CUSTOMER_IMPACT_ASSESSMENT

## Prevention Measures
$PREVENTION_MEASURES
EOF
```

## Common Scenarios and Solutions

### Scenario 1: OpenAI Batch API Rate Limiting
**Symptoms**: 429 errors, batch submissions failing
**Solution**:
```bash
# Reduce submission rate and implement exponential backoff
kubectl patch configmap batch-config -n primarch --patch '
data:
  rate_limits:
    submissions_per_minute: 5  # Reduced from 10
    retry_backoff_factor: 3.0  # Increased backoff
'
```

### Scenario 2: Large Batch Timeout
**Symptoms**: Batches >20K items timing out after 24 hours
**Solution**:
```bash
# Split large batches into smaller chunks
kubectl exec -n primarch deployment/batch-processor -- \
  python3 /app/scripts/split_large_batch.py \
    --batch-id $LARGE_BATCH_ID \
    --max-items-per-chunk 5000 \
    --preserve-priority true
```

### Scenario 3: S3 Export Pipeline Failure
**Symptoms**: Batches completing but exports failing
**Solution**:
```bash
# Check S3 permissions and retry exports
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT:role/batch-processor-role \
  --action-names s3:PutObject \
  --resource-arns arn:aws:s3:::$BATCH_EXPORT_BUCKET/*

# Retry failed exports
kubectl exec -n primarch deployment/batch-processor -- \
  python3 /app/scripts/retry_exports.py --status completed --missing-export
```

### Scenario 4: Memory/Disk Space Issues
**Symptoms**: Pod restarts, disk space alerts
**Solution**:
```bash
# Clean up temporary files
kubectl exec -n primarch deployment/batch-processor -- \
  find /tmp -name "*.jsonl" -mtime +1 -delete

# Increase pod resources
kubectl patch deployment batch-processor -n primarch --patch '
spec:
  template:
    spec:
      containers:
      - name: batch-processor
        resources:
          requests:
            memory: "4Gi"
            cpu: "2"
          limits:
            memory: "8Gi"
            cpu: "4"
'
```

## Prevention and Monitoring

### Proactive Monitoring
- Batch queue depth trending
- Success rate by profile tracking  
- SLA breach early warning (80% threshold)
- Export pipeline health checks

### Regular Maintenance
- Weekly batch size optimization review
- Monthly OpenAI quota and limit review
- Quarterly disaster recovery testing
- Export storage cleanup automation

### Alerting Thresholds
- Queue depth >50 items for >1 hour
- Success rate <95% for any profile
- Export failures >5% for any profile
- Processing time >20 hours for standard batches

---

**Last Updated**: 2025-09-30 | **Next Review**: 2025-10-30
**Owner**: Platform Engineering | **On-Call**: #primarch-ops
