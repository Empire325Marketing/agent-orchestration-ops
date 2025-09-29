-- Post-launch standard queries (read-only)

-- Golden win rate (last 24h)
SELECT
  SUM(CASE WHEN passed THEN 1 ELSE 0 END)::float / COUNT(*) AS win_rate
FROM analytics_golden_results
WHERE ts >= now() - interval '24 hours';

-- Error rate vs baseline (last 1h)
-- Join or compare to a stored baseline table if present
SELECT
  (SUM(errors)::float / NULLIF(SUM(requests),0)) AS err_rate_1h
FROM svc_hourly
WHERE ts >= now() - interval '1 hour';

-- Cost per request (last 24h)
SELECT
  SUM(estimated_cost_usd) / NULLIF(SUM(requests),0) AS cost_per_req_usd
FROM cost_rollup
WHERE ts >= now() - interval '24 hours';
