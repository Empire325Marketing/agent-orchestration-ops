# Cutover Checklist (Freeze → Shadow → Canary → Rollout)

## Pre-freeze (T-48h)
- [ ] Release candidate built & signed (Ch.10)
- [ ] Readiness gates green (Ch.13)
- [ ] Safety sets pass = 0 jailbreak/PII (Ch.17)
- [ ] Cost headroom ≥ 20% (Ch.12)
- [ ] Backups validated (Ch.15 restore check passes)
- [ ] Runbooks printed/linked (incident, rollback, overload)

## Freeze window (T-24h to T0)
- [ ] Code/config freeze declared
- [ ] On-call rota published
- [ ] Comms draft approved (status page, customer note)

## T0 Shadow (24–72h or as scoped)
- [ ] Shadow % by route per readiness/shadow_plan.md
- [ ] PII redaction confirmed
- [ ] No safety/cost/quality regressions

## T0+ Canary 10% (≥1h)
- [ ] p95 ≤ +20% vs baseline; error ≤ 1.25×
- [ ] win_rate ≥ 0.90 on golden set
- [ ] safety_ok = true; cost headroom ≥ 20%
- [ ] If breach ≥30m → rollback (auto)

## Rollout
- [ ] 10% → 50% → 100% per cicd/canary_rollout.md
- [ ] DECISIONS.log entry on each promotion/rollback

## Post-launch Day-0/1/7
- [ ] Day-0 smoke; Day-1 metrics review; Day-7 postmortem + learnings
