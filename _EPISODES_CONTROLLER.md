# Episodes Controller (Server Executor)

Constraints
- Operate only under /srv/primarch (text files) and /tmp for scratch.
- One ISO8601 UTC entry per episode in /srv/primarch/DECISIONS.log.
- Secrets from Vault paths:
  - kv/primarch/app/api/anthropic (key)
  - kv/primarch/app/api/github (token)
  - kv/primarch/app/api/serpapi (key)
  - kv/primarch/app/api/postgres (host,port,database,user,password)
- Redaction: print only first 5 chars + "…" of any token.

Helpers (conventions to use inside future episodes)
- vget PATH KEY -> read from Vault.
- Masked previews only, never echo full secrets.
- Idempotent writes to the files Operator requests.
- If blocked: print `BLOCKED: <reason>` and stop.

Episode template (paste as Operator next time)
------------------------------------------------
Role alignment (Chapter X or Task Name)
- Operator = iii. Executor = Claude (server). Path=/srv/primarch only.

Objective
<deliverables>

What you must do (idempotent)
<files/updates/log lines>

Output to Operator
- Print absolute paths changed (new vs updated) and the exact timestamp used.
