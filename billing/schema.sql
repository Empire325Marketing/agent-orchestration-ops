-- Billing Schema (Documentation Only - DO NOT EXECUTE)
-- Logical table definitions for usage metering and billing

-- Raw usage events from Gateway/Orchestrator
CREATE TABLE usage_events (
  event_id BIGSERIAL PRIMARY KEY,
  event_time TIMESTAMPTZ NOT NULL,
  tenant_id TEXT NOT NULL,
  route TEXT,                    -- API route (/v1/assist, /v1/tools/*)
  tool TEXT,                     -- tool name if applicable
  model TEXT,                    -- LLM model used
  meter TEXT NOT NULL,           -- tokens_in, tokens_out, tool_calls, etc.
  quantity NUMERIC(15,6) NOT NULL, -- amount consumed
  trace_id TEXT,                 -- correlation with observability
  metadata JSONB,                -- additional context
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Daily rollups for billing
CREATE TABLE usage_rollups_daily (
  rollup_id BIGSERIAL PRIMARY KEY,
  date DATE NOT NULL,
  tenant_id TEXT NOT NULL,
  meter TEXT NOT NULL,
  quantity NUMERIC(15,6) NOT NULL,
  cost NUMERIC(10,4),            -- calculated cost in USD
  anomalies JSONB,               -- detected anomalies (spikes, etc.)
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(date, tenant_id, meter)
);

-- Tenant pricing overrides
CREATE TABLE tenant_prices (
  tenant_id TEXT PRIMARY KEY,
  tier TEXT NOT NULL CHECK (tier IN ('free', 'pro', 'enterprise')),
  overrides JSONB,               -- custom rates, caps, discounts
  effective_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Monthly invoices
CREATE TABLE invoices (
  invoice_id TEXT PRIMARY KEY,   -- INV-YYYY-MM-tenant_id
  tenant_id TEXT NOT NULL,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  subtotal NUMERIC(10,2) NOT NULL,
  credits NUMERIC(10,2) DEFAULT 0,
  total NUMERIC(10,2) NOT NULL,
  status TEXT CHECK (status IN ('draft', 'sent', 'paid', 'overdue', 'disputed')),
  sent_at TIMESTAMPTZ,
  due_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Invoice line items
CREATE TABLE invoice_items (
  item_id BIGSERIAL PRIMARY KEY,
  invoice_id TEXT REFERENCES invoices(invoice_id),
  meter TEXT NOT NULL,
  quantity NUMERIC(15,6),
  rate NUMERIC(10,6),
  amount NUMERIC(10,2),
  description TEXT
);

-- Payment records
CREATE TABLE payments (
  payment_id TEXT PRIMARY KEY,
  invoice_id TEXT REFERENCES invoices(invoice_id),
  amount NUMERIC(10,2) NOT NULL,
  method TEXT,                   -- stripe, wire, credit, etc.
  status TEXT CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
  external_id TEXT,              -- payment processor reference
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Credits and adjustments
CREATE TABLE credits (
  credit_id BIGSERIAL PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  amount NUMERIC(10,2) NOT NULL,
  reason TEXT NOT NULL,          -- promo, sla_credit, dispute, etc.
  reference_id TEXT,             -- invoice_id, ticket_id, etc.
  expires_at DATE,
  created_by TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for performance
-- CREATE INDEX ON usage_events (tenant_id, event_time);
-- CREATE INDEX ON usage_events (meter, event_time);
-- CREATE INDEX ON usage_rollups_daily (tenant_id, date);
-- CREATE INDEX ON invoices (tenant_id, period_start);

-- Partitioning guidance
-- Partition usage_events by month (event_time)
-- Partition usage_rollups_daily by quarter (date)
-- Hot data: current + 2 months (fast SSD)
-- Warm data: 3-13 months (slower storage)
-- Archive: >13 months (cold storage, compliance retention)

-- Retention policy
-- usage_events: 13 months (legal/audit requirement)
-- usage_rollups_daily: 7 years (financial records)
-- invoices: 7 years (tax/audit requirement)
-- payments: 7 years (financial compliance)
