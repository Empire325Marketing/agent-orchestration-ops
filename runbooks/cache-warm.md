# Runbook — Cache Pre-warm
1) Compile top N keys from 24h analytics (Ch.20).
2) Generate request set (safe, non-PII) and execute against shadow env.
3) Verify hit rate lifts ≥ 0.10 vs baseline; record in SE dashboard.
4) Append DECISIONS.log with pre-warm window and delta.
