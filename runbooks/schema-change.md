# Runbook — Safe Schema Change (Contract-Aware)

1) Propose change + owner + rollback plan.
2) Add/update contract YAML and SQL checks.
3) Generate migration; run in shadow/staging; run DQ checks.
4) Canary deploy with gates; monitor alerts; verify no violations.
5) Promote or rollback; update lineage graph if new edges/datasets.
6) Append DECISIONS.log with outcome.
