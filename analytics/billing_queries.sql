-- Billing Analytics Queries (Standard KPIs)

-- ARPU (Average Revenue Per User) - monthly
SELECT 
  date_trunc('month', period_start) as month,
  COUNT(DISTINCT tenant_id) as active_tenants,
  SUM(total) as total_revenue,
  AVG(total) as arpu
FROM invoices 
WHERE status IN ('paid', 'sent')
  AND period_start >= current_date - interval '12 months'
GROUP BY 1
ORDER BY 1;

-- MRR (Monthly Recurring Revenue) approximation
WITH monthly_revenue AS (
  SELECT 
    date_trunc('month', period_start) as month,
    SUM(total) as revenue
  FROM invoices
  WHERE status = 'paid'
    AND period_start >= current_date - interval '6 months'
  GROUP BY 1
)
SELECT 
  month,
  revenue,
  LAG(revenue) OVER (ORDER BY month) as prev_month_revenue,
  revenue - LAG(revenue) OVER (ORDER BY month) as growth,
  ((revenue - LAG(revenue) OVER (ORDER BY month)) / 
   NULLIF(LAG(revenue) OVER (ORDER BY month), 0)) * 100 as growth_pct
FROM monthly_revenue
ORDER BY month;

-- Top meters by total cost (last 30 days)
SELECT 
  meter,
  COUNT(DISTINCT tenant_id) as unique_tenants,
  SUM(quantity) as total_quantity,
  SUM(cost) as total_cost,
  AVG(cost) as avg_cost_per_tenant
FROM usage_rollups_daily
WHERE date >= current_date - 30
GROUP BY meter
ORDER BY total_cost DESC;

-- Tenant cost headroom (vs. their tier caps)
WITH current_usage AS (
  SELECT 
    tenant_id,
    meter,
    SUM(quantity) as monthly_quantity
  FROM usage_rollups_daily
  WHERE date >= date_trunc('month', current_date)
  GROUP BY tenant_id, meter
),
tier_limits AS (
  SELECT 
    tp.tenant_id,
    tp.tier,
    cu.meter,
    cu.monthly_quantity,
    -- Get daily cap and multiply by days in month
    CASE tp.tier
      WHEN 'free' THEN 
        CASE cu.meter
          WHEN 'tokens_in' THEN 1000 * extract(day from current_date)
          WHEN 'tokens_out' THEN 1000 * extract(day from current_date)
          WHEN 'tool_calls' THEN 10 * extract(day from current_date)
          WHEN 'images_generated' THEN 0
          WHEN 'egress_bytes' THEN 1048576 * extract(day from current_date)
        END
      WHEN 'pro' THEN
        CASE cu.meter
          WHEN 'tokens_in' THEN 10000000 * extract(day from current_date)
          WHEN 'tokens_out' THEN 10000000 * extract(day from current_date)
          WHEN 'tool_calls' THEN 10000 * extract(day from current_date)
          WHEN 'images_generated' THEN 1000 * extract(day from current_date)
          WHEN 'egress_bytes' THEN 107374182400 * extract(day from current_date)
        END
      ELSE NULL  -- enterprise has no caps
    END as monthly_cap
  FROM tenant_prices tp
  JOIN current_usage cu ON cu.tenant_id = tp.tenant_id
)
SELECT 
  tenant_id,
  tier,
  meter,
  monthly_quantity,
  monthly_cap,
  CASE 
    WHEN monthly_cap IS NULL THEN 'unlimited'
    ELSE ROUND((monthly_quantity / NULLIF(monthly_cap, 0)) * 100, 2)::text || '%'
  END as utilization,
  CASE
    WHEN monthly_cap IS NULL THEN 'unlimited'
    WHEN monthly_quantity / NULLIF(monthly_cap, 0) > 0.8 THEN 'high_risk'
    WHEN monthly_quantity / NULLIF(monthly_cap, 0) > 0.6 THEN 'medium_risk'
    ELSE 'low_risk'
  END as headroom_status
FROM tier_limits
WHERE monthly_cap > 0 OR monthly_cap IS NULL
ORDER BY utilization DESC;

-- Unpaid invoices aging analysis
SELECT 
  CASE 
    WHEN current_date - due_at BETWEEN 1 AND 7 THEN '1-7 days'
    WHEN current_date - due_at BETWEEN 8 AND 14 THEN '8-14 days'
    WHEN current_date - due_at BETWEEN 15 AND 30 THEN '15-30 days'
    WHEN current_date - due_at > 30 THEN '30+ days'
    ELSE 'not_due'
  END as aging_bucket,
  COUNT(*) as invoice_count,
  SUM(total) as total_amount,
  ARRAY_AGG(tenant_id) as affected_tenants
FROM invoices 
WHERE status IN ('sent', 'overdue')
GROUP BY 1
ORDER BY 
  CASE 
    WHEN aging_bucket = 'not_due' THEN 0
    WHEN aging_bucket = '1-7 days' THEN 1  
    WHEN aging_bucket = '8-14 days' THEN 2
    WHEN aging_bucket = '15-30 days' THEN 3
    WHEN aging_bucket = '30+ days' THEN 4
  END;

-- Revenue breakdown by tier
WITH tier_revenue AS (
  SELECT 
    tp.tier,
    COUNT(DISTINCT i.tenant_id) as tenant_count,
    SUM(i.total) as total_revenue,
    AVG(i.total) as avg_invoice_amount
  FROM invoices i
  JOIN tenant_prices tp ON tp.tenant_id = i.tenant_id
  WHERE i.status = 'paid'
    AND i.period_start >= current_date - interval '3 months'
  GROUP BY tp.tier
)
SELECT 
  tier,
  tenant_count,
  total_revenue,
  avg_invoice_amount,
  ROUND((total_revenue / SUM(total_revenue) OVER ()) * 100, 2) as revenue_share_pct
FROM tier_revenue
ORDER BY total_revenue DESC;

-- Usage trends by meter (daily averages over last 30 days)
SELECT 
  meter,
  date,
  SUM(quantity) as daily_total,
  COUNT(DISTINCT tenant_id) as active_tenants,
  AVG(quantity) as avg_per_tenant
FROM usage_rollups_daily
WHERE date >= current_date - 30
GROUP BY meter, date
ORDER BY meter, date;
