
# Integration Tests

This directory contains the integration testing framework for the agent-orchestration-ops repository.

## Quick Start

```bash
# Install dependencies
pip install pytest requests

# Start test environment
docker compose -f compose.int.yml up -d

# Run all tests
pytest . -v

# Cleanup
docker compose -f compose.int.yml down -v
```

## Test Suites

- **test_router_smoke.py**: Basic health and functionality tests
- **test_fallbacks.py**: Provider failure and fallback behavior tests
- **test_cost_ledgers.py**: Cost tracking and attribution validation

## Documentation

See [docs/integration_tests.md](../docs/integration_tests.md) for comprehensive documentation including:
- Architecture overview
- Running tests locally
- CI/CD integration
- Test development guidelines
- Troubleshooting guide

## Environment Variables

- `ROUTER_URL`: Router base URL (default: `http://localhost:4000`)
- `HEALTH_TIMEOUT`: Seconds to wait for health (default: `60`)

## CI/CD

Tests run automatically on push and pull requests via GitHub Actions.
See `.github/workflows/integration.yml` for workflow configuration.
