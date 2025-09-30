# Runbook — Delete I-9 / Right-to-Work Records
1) Receive deletion request and verify identity/authority.
2) Check retention_matrix.yaml and confirm minimum window has elapsed.
3) Check for active legal_hold; if true, pause and notify Legal Ops.
4) Prepare erasure plan: messages, rag_chunks, and any linked tool_invocations.
5) Execute erasure in DB (MVP note: this runbook documents steps only).
6) Produce proof artifact (CSV/JSON) listing IDs and timestamps.
7) Update DECISIONS.log reference ID of proof artifact.