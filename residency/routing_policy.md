# Routing Policy (US/EU)

## Tenant → Region
- Tenant profile holds `region` = `us` or `eu`.
- Gateway injects `X-Primarch-Region` from tenant profile; requests without a region are denied.

## Gateway (Ch.6)
- Route tables select backend by `X-Primarch-Region`.
- Egress proxy enforces region allow-lists.

## Orchestrator
- Propagates `region` into auth context and DB connection selector.
- Deny if target storage/tool is out-of-region for **strict** classes.

## Storage
- Postgres clusters per region; connection pools keyed by region.
- Backups taken & stored only within region (Ch.15).

## Secrets (Ch.8)
- Use conceptual Vault namespaces: `kv/primarch/<region>/...`.

## Exports/Offboarding (Ch.25)
- Exports generated and delivered from/to the tenant's region only.

## Violations
- Cross-region write attempts → DLQ + alert.
- Cross-region read of strict classes → deny + audit.
