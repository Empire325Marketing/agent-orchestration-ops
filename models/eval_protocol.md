# Evaluation Protocol
Datasets: golden_tasks (functional), redteam (safety), latency_bench, cost_probe.
Metrics: win_rate, exact_match, factual_consistency, latency_p95, cost_per_req, toxicity_rate, pii_hits.
Procedure: run offline eval → shadow compare (24–72h) → canary (10%) → decision.
Storage: store results with build ID and image digest; link in DECISIONS and Audit Log (Ch.31).
