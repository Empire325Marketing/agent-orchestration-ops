# Immutability & Signing (Conceptual)
- Append-only policy enforced by process + runbooks; writes never UPDATE/DELETE.
- Daily partitions; each partition maintains a hash chain.
- Daily **anchor**: digest of partition hashes; optional signature (Ch.10 keys in Ch.8).
- Backups (Ch.15) validated by verifying anchors post-restore.
- Exports for investigations preserve order + chain; residency respected (Ch.30).
