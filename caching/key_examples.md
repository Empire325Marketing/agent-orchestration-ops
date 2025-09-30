# Cache Key Examples
- Assist deterministic:
  `cache:acme:/v1/assist:llama-3.1-8b:tool=None:sha256(templated_prompt):sha256(params):v1`
- Embeddings:
  `cache:acme:/v1/embeddings:llama-embed:dim=1536:sha256(norm(text)):v1`
- Web search:
  `cache:acme:/v1/tools/search_web:q=sha256(norm(query)):v1`
