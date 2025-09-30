-- Usage Aggregation Queries (Read-Only Examples)

-- Daily rollup from raw events
-- Run hourly to catch late-arriving events (6h window)
WITH daily_usage AS (
  SELECT 
    date_trunc('day', event_time)::date as usage_date,
    tenant_id,
    meter,
    SUM(quantity) as total_quantity
  FROM usage_events 
  WHERE event_time >= current_date - interval '7 days'
    AND event_time < current_date + interval '1 day'
  GROUP BY 1, 2, 3
),
cost_calculation AS (
  SELECT 
    du.usage_date,
    du.tenant_id,
    du.meter,
    du.total_quantity,
    -- Cost calculation based on tenant pricing
    CASE tp.tier
      WHEN 'free' THEN 0  -- free tier has no usage charges
      WHEN 'pro' THEN 
        du.total_quantity * COALESCE(
          (tp.overrides->>du.meter)::numeric,  -- custom rate
          (SELECT rate FROM standard_rates WHERE tier='pro' AND meter=du.meter)
        )
      WHEN 'enterprise' THEN
        du.total_quantity * COALESCE(
          (tp.overrides->>du.meter)::numeric,  -- custom enterprise rate
          (SELECT rate FROM standard_rates WHERE tier='enterprise' AND meter=du.meter)
        )
    END as calculated_cost
  FROM daily_usage du
  JOIN tenant_prices tp ON tp.tenant_id = du.tenant_id
)
-- INSERT INTO usage_rollups_daily or UPDATE existing
SELECT 
  usage_date as date,
  tenant_id,
  meter,
  total_quantity as quantity,
  calculated_cost as cost
FROM cost_calculation;

-- Anomaly detection (z-score method)
WITH usage_stats AS (
  SELECT 
    tenant_id,
    meter,
    AVG(quantity) as avg_quantity,
    STDDEV(quantity) as stddev_quantity
  FROM usage_rollups_daily 
  WHERE date >= current_date - interval '30 days'
  GROUP BY tenant_id, meter
),
anomaly_check AS (
  SELECT 
    urd.date,
    urd.tenant_id,
    urd.meter,
    urd.quantity,
    us.avg_quantity,
    us.stddev_quantity,
    ABS(urd.quantity - us.avg_quantity) / NULLIF(us.stddev_quantity, 0) as z_score
  FROM usage_rollups_daily urd
  JOIN usage_stats us ON us.tenant_id = urd.tenant_id AND us.meter = urd.meter
  WHERE urd.date = current_date - 1
)
SELECT *,
  CASE 
    WHEN z_score > 3 THEN 'high_anomaly'
    WHEN z_score > 2 THEN 'medium_anomaly'
    ELSE 'normal'
  END as anomaly_level
FROM anomaly_check
WHERE z_score > 2;

-- Percentage change detection
WITH yesterday AS (
  SELECT tenant_id, meter, quantity as yesterday_qty
  FROM usage_rollups_daily 
  WHERE date = current_date - 1
),
week_ago AS (
  SELECT tenant_id, meter, quantity as week_ago_qty
  FROM usage_rollups_daily
  WHERE date = current_date - 7
)
SELECT 
  y.tenant_id,
  y.meter,
  y.yesterday_qty,
  w.week_ago_qty,
  ((y.yesterday_qty - w.week_ago_qty) / NULLIF(w.week_ago_qty, 0)) * 100 as pct_change
FROM yesterday y
JOIN week_ago w ON w.tenant_id = y.tenant_id AND w.meter = y.meter
WHERE ABS(((y.yesterday_qty - w.week_ago_qty) / NULLIF(w.week_ago_qty, 0)) * 100) > 50;

-- Monthly invoice generation
WITH monthly_rollup AS (
  SELECT 
    tenant_id,
    meter,
    SUM(quantity) as total_quantity,
    SUM(cost) as total_cost
  FROM usage_rollups_daily
  WHERE date >= date_trunc('month', current_date - interval '1 month')
    AND date < date_trunc('month', current_date)
  GROUP BY tenant_id, meter
),
tenant_totals AS (
  SELECT 
    tenant_id,
    SUM(total_cost) as usage_charges,
    jsonb_agg(jsonb_build_object(
      'meter', meter,
      'quantity', total_quantity,
      'cost', total_cost
    )) as line_items
  FROM monthly_rollup
  GROUP BY tenant_id
)
SELECT 
  tenant_id,
  usage_charges,
  line_items,
  -- Add base fees based on tier
  CASE tp.tier
    WHEN 'pro' THEN usage_charges + 10.00
    WHEN 'enterprise' THEN GREATEST(usage_charges, 1000.00)  -- monthly minimum
    ELSE usage_charges
  END as subtotal
FROM tenant_totals tt
JOIN tenant_prices tp ON tp.tenant_id = tt.tenant_id;
