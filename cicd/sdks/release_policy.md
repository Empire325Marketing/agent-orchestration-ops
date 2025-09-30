# SDK Release Policy & CI/CD

## Release Strategy

### Semantic Versioning
- **MAJOR (X.0.0)**: Breaking API changes, authentication changes, new safety requirements
- **MINOR (X.Y.0)**: New features, model additions, backward-compatible enhancements
- **PATCH (X.Y.Z)**: Bug fixes, security patches, documentation updates

### Release Channels
```yaml
channels:
  stable:
    description: "Production-ready releases"
    testing: "Full test suite + manual QA"
    approval: "2 maintainers + security review"
    frequency: "Monthly or as needed for critical fixes"
  
  beta:
    description: "Feature preview with stability testing"
    testing: "Automated tests + limited user testing"
    approval: "1 maintainer + automated checks"
    frequency: "Bi-weekly"
  
  alpha:
    description: "Early feature access for testing"
    testing: "Basic automated tests"
    approval: "Automated checks only"
    frequency: "Weekly"
  
  nightly:
    description: "Daily builds from main branch"
    testing: "Unit tests + smoke tests"
    approval: "Automated"
    frequency: "Daily"
```

## CI/CD Pipeline

### Python SDK Pipeline
```yaml
# .github/workflows/python-sdk.yml
name: Python SDK CI/CD
on:
  push:
    branches: [main, develop]
    paths: ['sdks/python/**']
  pull_request:
    paths: ['sdks/python/**']
  release:
    types: [published]

jobs:
  test:
    strategy:
      matrix:
        python-version: ['3.8', '3.9', '3.10', '3.11', '3.12']
        os: [ubuntu-latest, windows-latest, macos-latest]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ matrix.python-version }}
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -e ".[dev]"
      
      - name: Lint with black and isort
        run: |
          black --check src/ tests/
          isort --check src/ tests/
      
      - name: Type check with mypy
        run: mypy src/primarch
      
      - name: Test with pytest
        run: |
          pytest tests/ --cov=primarch --cov-report=xml --cov-report=html
      
      - name: Integration tests
        env:
          PRIMARCH_API_KEY: ${{ secrets.TEST_API_KEY }}
        run: |
          pytest tests/integration/ --timeout=300
      
      - name: Security scan
        run: |
          bandit -r src/
          safety check
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml

  build:
    needs: test
    if: github.event_name == 'release'
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Build package
        run: |
          python -m pip install build
          python -m build
      
      - name: Verify package
        run: |
          pip install dist/*.whl
          python -c "import primarch; print(primarch.__version__)"
      
      - name: Publish to PyPI
        uses: pypa/gh-action-pypi-publish@release/v1
        with:
          password: ${{ secrets.PYPI_API_TOKEN }}
```

### JavaScript SDK Pipeline
```yaml
# .github/workflows/javascript-sdk.yml
name: JavaScript SDK CI/CD
on:
  push:
    branches: [main, develop]
    paths: ['sdks/javascript/**']
  pull_request:
    paths: ['sdks/javascript/**']
  release:
    types: [published]

jobs:
  test:
    strategy:
      matrix:
        node-version: ['16', '18', '20']
        os: [ubuntu-latest, windows-latest, macos-latest]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Lint
        run: npm run lint
      
      - name: Type check
        run: npm run typecheck
      
      - name: Test
        run: npm run test:coverage
      
      - name: Integration tests
        env:
          PRIMARCH_API_KEY: ${{ secrets.TEST_API_KEY }}
        run: npm run test:integration
      
      - name: Security audit
        run: npm audit --audit-level moderate
      
      - name: Bundle analysis
        run: npm run build && npm run analyze
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  build:
    needs: test
    if: github.event_name == 'release'
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          registry-url: 'https://registry.npmjs.org'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build
        run: npm run build
      
      - name: Verify package
        run: |
          npm pack --dry-run
          npm install -g ./primarch-sdk-*.tgz
          node -e "const p = require('@primarch/sdk'); console.log('SDK loaded successfully')"
      
      - name: Publish to npm
        run: npm publish
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

### CLI Pipeline
```yaml
# .github/workflows/cli.yml
name: CLI CI/CD
on:
  push:
    branches: [main, develop]
    paths: ['sdks/cli/**']
  pull_request:
    paths: ['sdks/cli/**']
  release:
    types: [published]

jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      
      - name: Test
        run: |
          go test ./... -v -race -coverprofile=coverage.out
          go tool cover -html=coverage.out -o coverage.html
      
      - name: Integration tests
        env:
          PRIMARCH_API_KEY: ${{ secrets.TEST_API_KEY }}
        run: go test ./tests/integration/... -timeout=5m
      
      - name: Security scan
        uses: securecodewarrior/github-action-gosec@master
        with:
          args: ./...
      
      - name: Lint
        uses: golangci/golangci-lint-action@v3
        with:
          version: latest

  build:
    needs: test
    if: github.event_name == 'release'
    
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        arch: [amd64, arm64]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      
      - name: Build binary
        env:
          GOOS: ${{ matrix.os == 'ubuntu-latest' && 'linux' || matrix.os == 'windows-latest' && 'windows' || 'darwin' }}
          GOARCH: ${{ matrix.arch }}
        run: |
          go build -ldflags="-s -w -X main.version=${{ github.ref_name }}" -o primarch${{ matrix.os == 'windows-latest' && '.exe' || '' }}
      
      - name: Create archive
        run: |
          if [ "${{ matrix.os }}" = "windows-latest" ]; then
            zip primarch-${{ matrix.os }}-${{ matrix.arch }}.zip primarch.exe
          else
            tar -czf primarch-${{ matrix.os }}-${{ matrix.arch }}.tar.gz primarch
          fi
      
      - name: Upload release assets
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url: ${{ github.event.release.upload_url }}
          asset_path: ./primarch-${{ matrix.os }}-${{ matrix.arch }}.*
          asset_name: primarch-${{ matrix.os }}-${{ matrix.arch }}.*
          asset_content_type: application/octet-stream
```

## Quality Gates

### Automated Checks
```yaml
quality_gates:
  code_coverage:
    minimum: 85%
    exclude_patterns: ["tests/", "*_test.py", "*.test.js"]
  
  security:
    vulnerability_scan: required
    dependency_audit: required
    secret_scan: required
  
  performance:
    bundle_size_js: "<500KB"
    cold_start_time: "<2s"
    memory_usage: "<100MB"
  
  compatibility:
    python_versions: ["3.8", "3.9", "3.10", "3.11", "3.12"]
    node_versions: ["16", "18", "20"]
    os_support: ["ubuntu", "windows", "macos"]
  
  documentation:
    api_docs: required
    examples: required
    changelog: required
```

### Release Approval Process
```yaml
approval_matrix:
  patch_release:
    automated_checks: required
    maintainer_approval: 1
    security_review: false
    user_testing: false
  
  minor_release:
    automated_checks: required
    maintainer_approval: 1
    security_review: true
    user_testing: beta_channel
  
  major_release:
    automated_checks: required
    maintainer_approval: 2
    security_review: required
    user_testing: alpha_beta_channels
    breaking_change_notice: "30_days"
```

## Testing Strategy

### Test Pyramid
```yaml
test_levels:
  unit_tests:
    coverage: ">90%"
    frameworks:
      python: "pytest"
      javascript: "jest"
      cli: "go test"
    
  integration_tests:
    coverage: ">70%"
    includes:
      - "API integration"
      - "Authentication flows"
      - "Error handling"
      - "Rate limiting"
    
  end_to_end_tests:
    coverage: "Critical paths"
    includes:
      - "Complete user workflows"
      - "Cross-platform compatibility"
      - "Performance benchmarks"
    
  safety_tests:
    coverage: "100% safety scenarios"
    includes:
      - "Content policy enforcement"
      - "PII detection"
      - "Prompt injection protection"
      - "Tool safety verification"
```

### Test Data Management
```yaml
test_data:
  synthetic_data:
    purpose: "Unit and integration tests"
    generation: "Automated via faker libraries"
    safety: "No real user data"
  
  curated_datasets:
    purpose: "Safety and quality validation"
    source: "Manual curation + community contributions"
    updates: "Monthly review and refresh"
  
  production_samples:
    purpose: "Performance and regression testing"
    anonymization: "Full PII removal"
    approval: "Security team + legal review"
```

## Security Integration

### Supply Chain Security
```yaml
security_measures:
  dependency_scanning:
    tools: ["Dependabot", "Snyk", "npm audit", "pip-audit"]
    frequency: "Daily"
    auto_fix: "Patch versions only"
  
  code_signing:
    required: true
    certificates: "Company-issued code signing certs"
    verification: "All release artifacts signed"
  
  provenance:
    slsa_level: 3
    build_attestation: required
    supply_chain_integrity: verified
  
  secrets_management:
    api_keys: "Stored in GitHub Secrets"
    signing_keys: "Hardware security modules"
    rotation: "Quarterly"
```

### Vulnerability Response
```yaml
vulnerability_process:
  detection:
    automated_scanning: "Daily"
    security_advisories: "Monitored"
    bug_bounty: "Active program"
  
  triage:
    critical: "4 hours"
    high: "24 hours"
    medium: "1 week"
    low: "1 month"
  
  remediation:
    patch_release: "Within SLA"
    communication: "Security advisory + changelog"
    verification: "Penetration testing"
```

## Monitoring & Observability

### Release Metrics
```yaml
metrics:
  adoption:
    downloads: "PyPI, npm, GitHub releases"
    active_users: "API key usage analytics"
    version_distribution: "Telemetry data"
  
  quality:
    error_rates: "Sentry integration"
    performance: "Response time monitoring"
    compatibility: "User-reported issues"
  
  security:
    vulnerability_count: "Security scanner reports"
    false_positive_rate: "Manual verification"
    time_to_remediation: "Issue tracking"
```

### Dashboard Integration
```yaml
dashboards:
  release_health:
    metrics: ["adoption", "error_rates", "performance"]
    alerts: ["High error rate", "Performance regression"]
    frequency: "Real-time"
  
  security_posture:
    metrics: ["vulnerability_count", "patch_coverage"]
    alerts: ["New vulnerabilities", "Patch delays"]
    frequency: "Daily"
  
  development_velocity:
    metrics: ["Release frequency", "Lead time", "MTTR"]
    alerts: ["Delayed releases", "Quality regression"]
    frequency: "Weekly"
```

## Cross-References
- Quality Gates: Chapter 13 (Readiness Gates)
- Security Integration: Chapter 8 (Secrets & IAM)
- Observability: Chapter 7 (OTel Integration)
- Safety Testing: Chapter 17 (Safety Red-Teaming)
