# Readiness — Experiments Gate

Pass criteria (per active experiment/variant):
- win_rate ≥ 0.90 (golden set)
- p95 regression ≤ +20% vs baseline
- error_rate ≤ 1.25× baseline
- safety_ok = true on curated sets (Ch.17)
- cost headroom ≥ 20%
- trace coverage ≥ 0.95 (1h)

Fail → block promotion (Ch.10), open incident/runbook, append DECISIONS.
