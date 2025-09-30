-- Ticketing schema (documentation; do not auto-apply)
CREATE TABLE support_tickets (
  id BIGSERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  channel TEXT CHECK (channel IN ('in_app','email','github','discord')),
  kind TEXT CHECK (kind IN ('bug','feature','question','safety')),
  severity TEXT CHECK (severity IN ('P1','P2','P3','P4')),
  status TEXT CHECK (status IN ('new','ack','in_progress','waiting','resolved','closed')) DEFAULT 'new',
  title TEXT NOT NULL,
  description TEXT,
  customer_id TEXT,
  tags TEXT[],
  pii_flag BOOLEAN DEFAULT false
);

CREATE TABLE support_events (
  id BIGSERIAL PRIMARY KEY,
  ticket_id BIGINT REFERENCES support_tickets(id),
  ts TIMESTAMPTZ NOT NULL DEFAULT now(),
  event TEXT,
  meta JSONB
);
