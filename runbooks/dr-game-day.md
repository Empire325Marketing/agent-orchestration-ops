# DR Game Day — Restore & Cutover (Doc-only)

## Objectives
Prove RPO ≤ 15m (PG WAL) and RTO ≤ 30m for primary DB.
Validate disaster recovery procedures and failover capabilities.

## Prerequisites
- [ ] Standby environment provisioned and accessible
- [ ] WAL-G backup system operational
- [ ] Monitoring dashboards available
- [ ] Communication channels established
- [ ] Rollback plan prepared

## Steps (Simulated)

### 1. Backup Selection & WAL Window Analysis
```bash
# Select backup snapshot T0
export BACKUP_TIMESTAMP="2025-09-30T17:00:00Z"
export WAL_WINDOW_START="2025-09-30T16:45:00Z"
export WAL_WINDOW_END="2025-09-30T17:15:00Z"

# Verify backup availability
wal-g backup-list | grep ${BACKUP_TIMESTAMP}
```

**Expected WAL window**: 15 minutes (meets RPO requirement)
**Backup size**: ~47GB (based on current DB size)

### 2. Restore to Standby (Simulation)
```bash
# Restore base backup
wal-g backup-fetch /var/lib/postgresql/13/main ${BACKUP_TIMESTAMP}

# Apply WAL files for PITR
wal-g wal-fetch 000000010000012300000045 /var/lib/postgresql/13/main/pg_wal/

# Configure recovery.conf
cat > recovery.conf << EOF
restore_command = 'wal-g wal-fetch %f %p'
recovery_target_time = '${WAL_WINDOW_END}'
recovery_target_action = 'promote'
EOF
```

**Simulated hosts**:
- Primary: `primarch-db-01.prod.internal`
- Standby: `primarch-db-standby.prod.internal`

### 3. Validation & Integrity Checks
```bash
# Start PostgreSQL on standby
systemctl start postgresql

# Run restore validation SQL
psql -f /srv/primarch/sql/restore_validation.sql > /tmp/restore_validation_output.txt

# Capture table sizes
psql -c "\dt+" > /tmp/table_sizes.txt
```

### 4. Traffic Cutover Simulation
```bash
# Update DNS/Load Balancer (simulated)
# Primary endpoint: primarch-db.prod.internal -> primarch-db-standby.prod.internal

# Update application config (simulated)
kubectl patch configmap primarch-config \
  --patch '{"data":{"DB_HOST":"primarch-db-standby.prod.internal"}}'

# Monitor connection health
for i in {1..60}; do
  pg_isready -h primarch-db-standby.prod.internal && echo "OK" || echo "FAIL"
  sleep 1
done
```

### 5. Performance Validation
```bash
# Compare p95 latency pre/post cutover
curl -s "http://prometheus:9090/api/v1/query?query=histogram_quantile(0.95,rate(http_request_duration_seconds_bucket[5m]))"

# Monitor error rates
curl -s "http://prometheus:9090/api/v1/query?query=rate(http_requests_total{status=~\"5..\"}[5m])/rate(http_requests_total[5m])"
```

## Evidence to Attach

### Database Snapshot Information
```sql
-- Table sizes and row counts
\dt+ 

-- Critical table verification
SELECT 'agents' as table_name, count(*) as row_count FROM agents
UNION ALL
SELECT 'tasks', count(*) FROM tasks
UNION ALL
SELECT 'executions', count(*) FROM executions
UNION ALL
SELECT 'audit_log', count(*) FROM audit_log;
```

### Integrity Verification
```sql
-- Audit chain verification (no breaks)
SELECT 
  min(created_at) as earliest_record,
  max(created_at) as latest_record,
  count(*) as total_records,
  md5(string_agg(audit_hash, '')) as chain_hash
FROM audit_log 
WHERE created_at BETWEEN '2025-09-30T16:45:00Z' AND '2025-09-30T17:15:00Z';
```

## Success Criteria
- [ ] **RPO ≤ 15 minutes**: WAL replay gap within acceptable window
- [ ] **RTO ≤ 30 minutes**: Full restore and cutover completed in time
- [ ] **Data Integrity**: All hash chains intact, zero data loss
- [ ] **Performance**: Post-cutover p95 within 10% of baseline
- [ ] **Error Rate**: < 0.1% during cutover window

## Rollback Procedures
```bash
# Emergency rollback to primary (if needed)
kubectl patch configmap primarch-config \
  --patch '{"data":{"DB_HOST":"primarch-db-01.prod.internal"}}'

# Verify primary database health
pg_isready -h primarch-db-01.prod.internal
```

## Communication Protocol
1. **T-30m**: Announce DR exercise start
2. **T-0**: Begin restore process
3. **T+15m**: Restore validation checkpoint
4. **T+25m**: Cutover execution
5. **T+30m**: Success/failure declaration
6. **T+60m**: Post-exercise debrief

## Risk Mitigation
- **Backup Corruption**: Multiple backup retention (3 days)
- **Network Issues**: Direct database access via jump host
- **WAL Gap**: Continuous archiving monitoring
- **Application Errors**: Circuit breaker patterns enabled

## Post-Exercise Actions
- [ ] Update RTO/RPO measurements in DECISIONS.log
- [ ] Document any issues encountered
- [ ] Schedule follow-up improvements
- [ ] Archive exercise evidence
- [ ] Update runbook based on lessons learned

---
**Exercise Type**: Simulated (Non-disruptive)  
**Frequency**: Monthly  
**Next Scheduled**: 2025-10-30  
**Owner**: SRE Team + DBA
