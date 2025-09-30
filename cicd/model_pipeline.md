# Model Pipeline (CI/CD)
Jobs: eval → safety → provenance → shadow → canary → promote/rollback.
Artifacts: eval_report.json, safety_report.json, sbom.json, attestations/*.intoto.jsonl.
Policy: block on readiness gate fail; always append DECISIONS on promote/rollback.
