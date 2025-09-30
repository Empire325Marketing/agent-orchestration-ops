# Supply Chain Security

## SBOM (Software Bill of Materials) Plan

### Tooling Selection
- **Primary tool**: syft for container image SBOM generation
- **Format**: SPDX 2.3 JSON format for compliance compatibility
- **Integration**: Embedded in Security Pipeline (cicd/pipelines.md)
- **Storage**: Vault backend with 90-day retention (Chapter 8 integration)

### SBOM Generation Process
1. **Build-time scanning**: Scan final container images before deployment
2. **Dependency analysis**: Include all OS packages, language packages, and binaries
3. **Version tracking**: Capture exact versions and checksums
4. **License detection**: Identify software licenses for compliance
5. **Vulnerability mapping**: Cross-reference with known vulnerability databases

### SBOM Contents
```json
{
  "spdxVersion": "SPDX-2.3",
  "creationInfo": {
    "created": "<ISO8601-timestamp>",
    "creators": ["Tool: syft", "Organization: Primarch-CI"]
  },
  "name": "primarch-<component>-<version>",
  "packages": [
    {
      "name": "<package-name>",
      "versionInfo": "<version>",
      "downloadLocation": "<source-url>",
      "filesAnalyzed": true,
      "checksums": [{"algorithm": "SHA256", "value": "<hash>"}],
      "licenseConcluded": "<license>",
      "externalRefs": [{"referenceCategory": "SECURITY", "referenceType": "cpe23Type", "referenceLocator": "<cpe>"}]
    }
  ]
}
```

## Image Signing Approach

### Signing Infrastructure
- **Signing keys**: Managed in Vault with 30-day rotation (Chapter 8)
- **Signing tool**: cosign for container image signing
- **Key storage**: Vault transit engine for signing operations
- **Verification**: Admission controller verifies signatures at deployment

### Signing Process
1. **Image build**: Container image built in secure environment
2. **Vulnerability scan**: No critical vulnerabilities before signing
3. **Key retrieval**: Fetch signing key from Vault transit engine
4. **Signature generation**: Create cosign signature with metadata
5. **Registry upload**: Push signed image and signature to registry

### Signature Verification
- **Deployment-time**: Kubernetes admission controller verifies signatures
- **Public key distribution**: Verification keys stored in cluster secrets
- **Policy enforcement**: Unsigned images rejected automatically
- **Emergency override**: Chapter 8 break-glass for emergency deployments

### Cosign Integration
```bash
# Sign image with Vault-managed key
cosign sign --key vault://primarch/signing-key <image-url>

# Verify signature
cosign verify --key vault://primarch/signing-key-pub <image-url>

# Generate attestation
cosign attest --key vault://primarch/signing-key --predicate sbom.json <image-url>
```

## Provenance Statement Contents

### In-Toto Attestation Format
```json
{
  "_type": "https://in-toto.io/Statement/v0.1",
  "subject": [{"name": "<image-url>", "digest": {"sha256": "<hash>"}}],
  "predicateType": "https://slsa.dev/provenance/v0.2",
  "predicate": {
    "builder": {"id": "https://github.com/primarch/ci"},
    "buildType": "https://github.com/Attestations/GitHubActionsWorkflow@v1",
    "invocation": {
      "configSource": {
        "uri": "<repo-url>",
        "digest": {"sha1": "<commit-sha>"},
        "entryPoint": ".github/workflows/build.yml"
      },
      "parameters": {"workflow-inputs": {}},
      "environment": {"github": {"workflow_ref": "<ref>"}}
    },
    "metadata": {
      "buildInvocationId": "<build-id>",
      "buildStartedOn": "<timestamp>",
      "buildFinishedOn": "<timestamp>",
      "completeness": {"parameters": true, "environment": true, "materials": true},
      "reproducible": false
    },
    "materials": [
      {"uri": "<dependency-url>", "digest": {"sha256": "<hash>"}}
    ]
  }
}
```

### Required Provenance Data
- **Source repository**: Git URL and commit SHA
- **Build environment**: CI system details and runner information
- **Build process**: Workflow definition and execution parameters
- **Dependencies**: All build-time dependencies with checksums
- **Timeline**: Start/end timestamps for build process
- **Artifacts**: Output artifacts with integrity hashes

## Attestation Storage Locations

### Primary Storage (Vault)
- **Path**: `secret/primarch/attestations/<image-hash>/`
- **Contents**: Provenance statements, SBOM data, signing metadata
- **Retention**: 90 days active, archived for compliance
- **Access control**: Vault policies for CI/CD and audit access

### Secondary Storage (Container Registry)
- **Location**: OCI registry as attestation layers
- **Format**: Cosign attestation format
- **Discovery**: Linked to container images via digest
- **Replication**: Multi-region for availability

### Archive Storage (Compliance)
- **Location**: Long-term compliance archive
- **Retention**: 1 year for audit requirements
- **Format**: Immutable archive with integrity verification
- **Access**: Read-only for compliance and audit teams

### Storage Schema
```yaml
vault_path: secret/primarch/attestations/<image-sha256>/
contents:
  sbom.json: <SPDX-format-SBOM>
  provenance.json: <in-toto-attestation>
  signature.json: <cosign-signature-metadata>
  build_metadata.json: <ci-specific-metadata>
metadata:
  created: <timestamp>
  retention_until: <timestamp>
  compliance_archive: <archive-location>
```

## Vulnerability Management

### Scanning Integration
- **Base image scanning**: Weekly scans of base container images
- **Dependency scanning**: Real-time scanning of package dependencies
- **Policy enforcement**: Block deployment of critical vulnerabilities
- **Exception process**: Security team approval for non-fixable vulnerabilities

### Vulnerability Database
- **Sources**: NVD, GitHub Security Advisories, vendor-specific databases
- **Update frequency**: Daily database updates
- **Alert integration**: Chapter 7 observability for vulnerability notifications
- **Remediation tracking**: Link vulnerabilities to fix commits

## Compliance Integration

### Audit Requirements
- **SBOM retention**: 90 days minimum for compliance (Chapter 9)
- **Signing verification**: All production images must be signed
- **Provenance tracking**: Build-to-deployment traceability required
- **Vulnerability documentation**: Risk acceptance for unfixable issues

### Reporting
- **Monthly SBOM reports**: Compliance team receives automated reports
- **Vulnerability dashboard**: Real-time view of security posture
- **Signing compliance**: Percentage of signed vs unsigned deployments
- **Supply chain metrics**: Build integrity and provenance coverage

## Cross-References
- Key management: Chapter 8 Vault integration
- Pipeline integration: cicd/pipelines.md Security Pipeline
- Compliance requirements: Chapter 9 retention and audit
- Emergency procedures: Chapter 8 break-glass for deployment overrides