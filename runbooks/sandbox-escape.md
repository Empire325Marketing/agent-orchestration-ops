# Runbook — Sandbox Escape Suspected
1) Quarantine: stop new tasks; block egress at gateway; snapshot container state.
2) Collect: hashes of binaries, recent logs, OTel traces, list of open FDs.
3) Rotate all secrets; invalidate tokens; add temporary broader blocklist.
4) Root cause: diff filesystem and process tree; identify exploit vector.
5) Remediate: patch image; add regression test; reopen traffic gradually.
6) Log: DECISIONS.log entry with incident ID and actions taken.