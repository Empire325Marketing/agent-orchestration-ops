# Runbook — Experiments Lifecycle

1) Propose: add entry in `experiments.yaml` with owner, metrics, guardrails.
2) Review: privacy + safety checks (Ch.17), readiness gates (Ch.13).
3) Launch: set allocations/steps; confirm dashboards and alerts are live.
4) Monitor: watch p95, error-rate, win_rate, safety_ok, cost headroom.
5) Decide: promote if green for window; rollback if guardrail red ≥30m.
6) Record: append DECISIONS.log; archive results; update risk register (Ch.14).
