# Runbook — Apply / Clear Legal Hold
1) Receive request from Legal Ops; record scope and case ID.
2) Tag affected records with legal_hold=true (document-only at MVP).
3) Pause all deletion flows for tagged records.
4) On clearance, remove tag and resume scheduled deletion.