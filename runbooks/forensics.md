# Runbook — Forensics (Chain-of-Custody)
1) **Preserve**: snapshot relevant partitions; halt rotation for scope window.
2) **Extract**: export ordered records + anchors; record SHA256 for each file.
3) **Verify**: recompute hash chain; compare with anchors; note any gaps.
4) **Correlate**: join with traces (Ch.7), readiness results (Ch.13), and safety logs (Ch.17/26).
5) **Report**: fill chain_of_custody.md, attach artifacts, append DECISIONS.log with outcome.
