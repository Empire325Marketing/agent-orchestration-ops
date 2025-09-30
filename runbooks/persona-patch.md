# Persona Patch Management

## Objective
Update FRANK persona assets, maintain registry consistency, and ensure seamless deployment of persona improvements and fixes.

## Patch Types

### Content Patches
- Knowledge base updates and corrections
- Voice/personality refinements
- Directive clarifications
- Example conversation improvements

### Security Patches  
- Safety guideline updates
- Firewall profile adjustments
- Vulnerability fixes
- Compliance requirement updates

### Performance Patches
- Response optimization
- Consistency improvements
- Integration enhancements
- Tool usage refinements

## Patch Process

### Step 1: Asset Preparation
1. **Identify Changes Required**
   ```yaml
   patch_request:
     id: "FRANK-PATCH-001"
     type: "content|security|performance"
     priority: "low|medium|high|critical"
     assets_affected:
       - "FRANK_KNOWLEDGE_CORE.pdf"
       - "FRANK_VOICE_AND_PERSONALITY.txt"
     description: "Update knowledge base with latest domain expertise"
     impact: "Improved accuracy in specialized topics"
   ```

2. **Asset Modification**
   ```bash
   # Backup current assets
   cp FRANK_KNOWLEDGE_CORE.pdf FRANK_KNOWLEDGE_CORE_backup_$(date +%Y%m%d).pdf
   
   # Apply changes to assets
   # (Manual editing or automated tooling)
   
   # Validate asset format
   python asset_validator.py FRANK_KNOWLEDGE_CORE.pdf
   ```

3. **Change Documentation**
   - Document specific changes made
   - Explain rationale for modifications
   - Identify potential impact areas
   - Reference source materials or requirements

### Step 2: Registry Update
1. **Version Increment**
   ```yaml
   # Update personas/registry.yaml
   personas:
     - id: frank
       version: 2  # Increment version
       updated_at: "2025-09-27T12:00:00Z"
       changelog: "Enhanced knowledge base with quantum computing expertise"
       assets:
         voice_doc: "FRANK_VOICE_AND_PERSONALITY.txt"
         core_directives: "FRANK_CORE_DIRECTIVES.txt"
         knowledge:
           - "FRANK_KNOWLEDGE_CORE.pdf"  # Updated asset
   ```

2. **Registry Validation**
   ```bash
   # Validate registry syntax
   python -m yaml.tool personas/registry.yaml
   
   # Check asset references
   python registry_validator.py personas/registry.yaml
   
   # Verify version consistency
   python version_checker.py --registry personas/registry.yaml
   ```

### Step 3: Manifest Regeneration
1. **Calculate New Checksums**
   ```bash
   # Generate updated manifest
   cat > personas/FRANK_MANIFEST.md <<EOF
   # FRANK Persona Asset Manifest
   
   Version: 2
   Updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
   
   ## Asset Inventory
   EOF
   
   # Add checksum for each asset
   for file in FRANK_*.txt FRANK_*.pdf; do
     if [ -f "personas/$file" ]; then
       size=$(stat -c%s "personas/$file")
       hash=$(sha256sum "personas/$file" | cut -d' ' -f1)
       echo "### $file" >> personas/FRANK_MANIFEST.md
       echo "- **Size**: $size bytes" >> personas/FRANK_MANIFEST.md
       echo "- **SHA256**: $hash" >> personas/FRANK_MANIFEST.md
       echo "" >> personas/FRANK_MANIFEST.md
     fi
   done
   ```

2. **Integrity Verification**
   ```bash
   # Verify all checksums
   cd personas/
   sha256sum -c <(grep SHA256 FRANK_MANIFEST.md | sed 's/.*SHA256**: //' | sed 's/^/FRANK_/')
   ```

### Step 4: Testing & Validation
1. **Consistency Testing**
   ```bash
   # Test persona consistency
   python persona_consistency_test.py --persona frank --version 2
   
   # Check voice alignment
   python voice_validator.py --voice FRANK_VOICE_AND_PERSONALITY.txt
   
   # Validate knowledge accuracy
   python knowledge_tester.py --knowledge FRANK_KNOWLEDGE_CORE.pdf
   ```

2. **Safety Evaluation**
   ```bash
   # Run safety test suite
   python safety_evaluator.py --persona frank --test-suite comprehensive
   
   # Check firewall compatibility
   python firewall_compatibility_test.py --persona frank --profile promptguard_v2
   ```

3. **Integration Testing**
   ```bash
   # Test tool integrations
   python tool_integration_test.py --persona frank
   
   # Validate API responses
   python api_consistency_test.py --persona frank --version 2
   ```

### Step 5: Deployment
1. **Staging Deployment**
   ```bash
   # Deploy to staging environment
   kubectl apply -f persona-staging-deployment.yaml
   
   # Update staging registry
   kubectl create configmap frank-registry-v2 --from-file=personas/registry.yaml
   ```

2. **Production Deployment**
   ```bash
   # Deploy to production
   kubectl set image deployment/frank-persona persona=frank:v2
   
   # Update registry configmap
   kubectl create configmap frank-registry --from-file=personas/registry.yaml --dry-run=client -o yaml | kubectl apply -f -
   
   # Verify deployment
   kubectl rollout status deployment/frank-persona
   ```

3. **Post-Deployment Verification**
   ```bash
   # Check persona responses
   curl -X POST /api/v1/assist -d '{"input": "test consistency", "persona": "frank"}'
   
   # Monitor metrics
   prometheus_query 'persona_consistency_score{persona="frank"}'
   
   # Verify asset loading
   kubectl logs -l app=frank-persona | grep "Assets loaded successfully"
   ```

## Asset Management Best Practices

### Version Control
```bash
# Track all changes in git
git add personas/FRANK_*.txt personas/FRANK_*.pdf
git add personas/registry.yaml personas/FRANK_MANIFEST.md
git commit -m "FRANK-PATCH-001: Enhanced knowledge base"
git tag -a frank-v2 -m "FRANK persona version 2"
```

### Backup Strategy
```bash
# Automated backup before changes
backup_dir="/backup/personas/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"
cp personas/FRANK_* "$backup_dir/"
cp personas/registry.yaml "$backup_dir/"
```

### Asset Validation Rules
1. **File Format**: Must be valid text or PDF
2. **Size Limits**: Text files <1MB, PDF files <10MB
3. **Character Encoding**: UTF-8 only
4. **Content Guidelines**: Must align with FRANK persona
5. **Safety Requirements**: No prohibited content

## Rollback Procedures

### Quick Rollback
```bash
# Revert to previous version
kubectl rollout undo deployment/frank-persona

# Restore previous registry
kubectl create configmap frank-registry --from-file=backup/registry.yaml

# Verify rollback
kubectl get deployment frank-persona -o jsonpath='{.metadata.labels.version}'
```

### Asset-Specific Rollback
```bash
# Restore specific asset
cp backup/FRANK_KNOWLEDGE_CORE.pdf personas/

# Update manifest
python regenerate_manifest.py --version rollback

# Redeploy with corrected asset
kubectl rollout restart deployment/frank-persona
```

## Quality Gates

### Pre-Deployment
- [ ] Asset validation passes
- [ ] Registry syntax correct
- [ ] Manifest checksums valid
- [ ] Consistency tests pass
- [ ] Safety evaluation clean
- [ ] Integration tests successful

### Post-Deployment
- [ ] Persona loads successfully
- [ ] Response quality maintained
- [ ] Consistency metrics stable
- [ ] No safety violations
- [ ] User experience preserved

## Monitoring & Alerts

### Key Metrics
- Asset loading success rate
- Persona consistency score
- Response accuracy metrics
- User satisfaction ratings
- Safety violation counts

### Alert Conditions
- Asset loading failures
- Consistency score < 0.8
- Safety violations detected
- User satisfaction decline
- Performance degradation

## DECISIONS.log Entry

```
<TIMESTAMP> | OPERATOR=<patch_manager> | ACTION=persona_patch_applied | PATCH_ID=<patch_id> | VERSION=<new_version> | ASSETS=<asset_list> | VALIDATION=<pass/fail> | EXECUTOR=<system>
```

## Documentation Updates

### Change Log Maintenance
```markdown
# FRANK Persona Change Log

## Version 2.0 (2025-09-27)
- Enhanced knowledge base with quantum computing expertise
- Improved voice consistency in technical discussions
- Updated core directives for better safety compliance
- Added 50+ new conversation examples

## Version 1.1 (2025-09-20)
- Fixed personality inconsistencies in formal contexts
- Updated knowledge base with recent industry developments
- Improved tool usage guidance
```

### User Communication
- Notify users of significant improvements
- Update documentation and help materials
- Provide migration guides if behavior changes
- Collect feedback on patch effectiveness
