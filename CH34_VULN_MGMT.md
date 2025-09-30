# Chapter 34 — Vulnerability Management & Patch Cadence

## Decision Summary
Adopt a unified vulnerability management program tying **SBOM & signing (Ch.10)**, **Audit/Forensics (Ch.31)**,
**SIEM detections (Ch.33)**, and **Readiness gates (Ch.13)**. Define SLAs by severity, enforce CI/CD fail-criteria,
and operate a recurring patch window with exception control.

## Scope
- Sources: SBOM scanners, image/package scanners, CVE feeds, config/secret checks.
- SLAs: Critical 48h, High 7d, Medium 30d, Low 90d.
- Readiness gate + alerts; runbooks for triage and patch execution.
- Exception workflow with explicit risk acknowledgment.

## Non-goals
- Running live scanners or external feeds (documentation-only).
- Full ITSM integration (future).

## Ties
Ch.7 observability, Ch.8 secrets, Ch.9 compliance, Ch.10 supply chain, Ch.12 cost guardrails,
Ch.19 go-live/rollback, Ch.31 immutable audit, Ch.33 SIEM bridge.
