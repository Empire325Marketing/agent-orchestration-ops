# Runbook — Model Brownout
1) Enter slow mode: lower max_output_tokens, cap temperature, block long-context.
2) If still burning: enter stop mode; reject long-context; require operator override.
3) Keep OTel spans/metrics for before/after; attach to incident timeline.
4) Exit criteria: burn < 1× for 4 hours and SLOs stable.