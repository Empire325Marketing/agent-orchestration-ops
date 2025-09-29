
#!/bin/bash

# Documentation Drift Check Script
# Ensures documentation stays aligned with platform changes

set -e

echo "🔍 Starting documentation drift check..."

# Configuration
DOCS_DIR="docs"
MAX_AGE_DAYS=30
PLATFORM_TERMS=("kubernetes" "docker" "aws" "azure" "gcp" "terraform" "helm" "agent" "orchestration")
REQUIRED_DOCS=("README.md" "DECISIONS.log")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
WARNINGS=0
ERRORS=0

echo_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
    ((ERRORS++))
}

# Check if required documentation exists
check_required_docs() {
    echo_info "Checking for required documentation files..."
    
    for doc in "${REQUIRED_DOCS[@]}"; do
        if [ -f "$doc" ]; then
            echo_success "Found required documentation: $doc"
        else
            echo_error "Missing required documentation: $doc"
        fi
    done
}

# Check documentation freshness
check_doc_freshness() {
    echo_info "Checking documentation freshness..."
    
    if [ ! -d "$DOCS_DIR" ]; then
        echo_warning "Documentation directory '$DOCS_DIR' not found"
        return
    fi
    
    # Find all markdown files
    total_docs=$(find . -name "*.md" -type f | grep -v ".git" | wc -l)
    
    if [ $total_docs -eq 0 ]; then
        echo_warning "No markdown documentation files found"
        return
    fi
    
    # Find recently updated files
    recent_docs=$(find . -name "*.md" -type f -mtime -$MAX_AGE_DAYS | grep -v ".git" | wc -l)
    
    if [ $total_docs -gt 0 ]; then
        freshness_ratio=$((recent_docs * 100 / total_docs))
        echo_info "Documentation freshness: $freshness_ratio% ($recent_docs/$total_docs files updated in last $MAX_AGE_DAYS days)"
        
        if [ $freshness_ratio -lt 20 ]; then
            echo_warning "Low documentation freshness ($freshness_ratio%) - consider updating documentation"
        else
            echo_success "Good documentation freshness ($freshness_ratio%)"
        fi
    fi
    
    # List stale documentation
    echo_info "Checking for stale documentation (older than $MAX_AGE_DAYS days)..."
    stale_docs=$(find . -name "*.md" -type f -mtime +$MAX_AGE_DAYS | grep -v ".git")
    
    if [ -n "$stale_docs" ]; then
        echo_warning "Stale documentation files found:"
        echo "$stale_docs" | while read -r file; do
            last_modified=$(stat -c %y "$file" 2>/dev/null || stat -f %Sm "$file" 2>/dev/null || echo "unknown")
            echo "  - $file (last modified: $last_modified)"
        done
    else
        echo_success "No stale documentation found"
    fi
}

# Check platform alignment
check_platform_alignment() {
    echo_info "Checking platform alignment..."
    
    total_refs=0
    
    for term in "${PLATFORM_TERMS[@]}"; do
        refs=$(find . -name "*.md" -type f -exec grep -l -i "$term" {} \; 2>/dev/null | grep -v ".git" | wc -l)
        if [ $refs -gt 0 ]; then
            echo_info "Found $refs references to '$term'"
            total_refs=$((total_refs + refs))
        fi
    done
    
    if [ $total_refs -gt 0 ]; then
        echo_success "Found $total_refs platform-specific references across documentation"
    else
        echo_warning "No platform-specific references found - documentation may need platform alignment"
    fi
}

# Check for broken internal links
check_internal_links() {
    echo_info "Checking internal documentation links..."
    
    broken_links=0
    
    # Find all markdown files and check internal links
    while IFS= read -r -d '' md_file; do
        # Extract relative markdown links
        while IFS= read -r link; do
            if [ -n "$link" ]; then
                # Convert relative path to absolute path from the md_file location
                link_dir=$(dirname "$md_file")
                full_path="$link_dir/$link"
                
                if [ ! -f "$full_path" ]; then
                    echo_warning "Broken link in $md_file: $link"
                    ((broken_links++))
                fi
            fi
        done < <(grep -o '\[.*\]([^)]*\.md)' "$md_file" 2>/dev/null | sed 's/.*(\([^)]*\)).*/\1/' || true)
    done < <(find . -name "*.md" -type f -print0 | grep -z -v ".git")
    
    if [ $broken_links -eq 0 ]; then
        echo_success "All internal documentation links are valid"
    else
        echo_warning "Found $broken_links broken internal links"
    fi
}

# Check documentation structure
check_doc_structure() {
    echo_info "Checking documentation structure..."
    
    # Check for common documentation patterns
    patterns=("## Overview" "## Prerequisites" "## Installation" "## Usage" "## Configuration")
    
    docs_with_structure=0
    total_readme_docs=0
    
    while IFS= read -r -d '' md_file; do
        if [[ $(basename "$md_file") == "README.md" ]] || [[ $(basename "$md_file") == "readme.md" ]]; then
            ((total_readme_docs++))
            
            structure_score=0
            for pattern in "${patterns[@]}"; do
                if grep -q "$pattern" "$md_file"; then
                    ((structure_score++))
                fi
            done
            
            if [ $structure_score -ge 2 ]; then
                ((docs_with_structure++))
            else
                echo_warning "$(basename "$md_file") in $(dirname "$md_file") lacks standard structure (found $structure_score/5 common sections)"
            fi
        fi
    done < <(find . -name "*.md" -type f -print0 | grep -z -v ".git")
    
    if [ $total_readme_docs -gt 0 ]; then
        structure_ratio=$((docs_with_structure * 100 / total_readme_docs))
        echo_info "Documentation structure compliance: $structure_ratio% ($docs_with_structure/$total_readme_docs README files)"
        
        if [ $structure_ratio -lt 50 ]; then
            echo_warning "Low documentation structure compliance - consider standardizing documentation format"
        else
            echo_success "Good documentation structure compliance"
        fi
    fi
}

# Check for TODO/FIXME items in documentation
check_todo_items() {
    echo_info "Checking for TODO/FIXME items in documentation..."
    
    todo_count=0
    
    while IFS= read -r -d '' md_file; do
        todos=$(grep -n -i -E "(TODO|FIXME|XXX|HACK)" "$md_file" 2>/dev/null || true)
        if [ -n "$todos" ]; then
            echo_warning "Found TODO/FIXME items in $md_file:"
            echo "$todos" | sed 's/^/  /'
            todo_count=$((todo_count + $(echo "$todos" | wc -l)))
        fi
    done < <(find . -name "*.md" -type f -print0 | grep -z -v ".git")
    
    if [ $todo_count -eq 0 ]; then
        echo_success "No TODO/FIXME items found in documentation"
    else
        echo_warning "Found $todo_count TODO/FIXME items in documentation"
    fi
}

# Generate drift report
generate_report() {
    echo_info "Generating documentation drift report..."
    
    report_file="docs-drift-report.md"
    
    cat > "$report_file" << EOF
# Documentation Drift Report

**Generated:** $(date -u '+%Y-%m-%d %H:%M:%S UTC')
**Repository:** agent-orchestration-ops
**Branch:** $(git branch --show-current 2>/dev/null || echo "unknown")

## Summary

- **Total Warnings:** $WARNINGS
- **Total Errors:** $ERRORS
- **Overall Status:** $([ $ERRORS -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")

## Checks Performed

1. ✅ Required documentation files
2. ✅ Documentation freshness
3. ✅ Platform alignment
4. ✅ Internal link validation
5. ✅ Documentation structure
6. ✅ TODO/FIXME tracking

## File Statistics

- **Total Markdown Files:** $(find . -name "*.md" -type f | grep -v ".git" | wc -l)
- **Documentation Directories:** $(find . -type d -name "*doc*" | grep -v ".git" | wc -l)
- **Recently Updated:** $(find . -name "*.md" -type f -mtime -$MAX_AGE_DAYS | grep -v ".git" | wc -l)

## Recommendations

EOF

    if [ $WARNINGS -gt 0 ] || [ $ERRORS -gt 0 ]; then
        echo "- Review and address the warnings and errors identified above" >> "$report_file"
        echo "- Consider implementing a regular documentation review process" >> "$report_file"
        echo "- Update stale documentation to reflect current platform state" >> "$report_file"
    else
        echo "- Documentation appears to be well-maintained" >> "$report_file"
        echo "- Continue regular documentation updates" >> "$report_file"
    fi
    
    echo "" >> "$report_file"
    echo "---" >> "$report_file"
    echo "*Report generated by docs/drift_check.sh*" >> "$report_file"
    
    echo_success "Documentation drift report generated: $report_file"
}

# Main execution
main() {
    echo "📋 Documentation Drift Check for Agent Orchestration Operations"
    echo "=============================================================="
    echo ""
    
    check_required_docs
    echo ""
    
    check_doc_freshness
    echo ""
    
    check_platform_alignment
    echo ""
    
    check_internal_links
    echo ""
    
    check_doc_structure
    echo ""
    
    check_todo_items
    echo ""
    
    generate_report
    echo ""
    
    # Final summary
    echo "=============================================================="
    echo_info "Documentation drift check completed"
    echo_info "Warnings: $WARNINGS"
    echo_info "Errors: $ERRORS"
    
    if [ $ERRORS -eq 0 ]; then
        echo_success "Documentation drift check PASSED"
        exit 0
    else
        echo_error "Documentation drift check FAILED"
        exit 1
    fi
}

# Run main function
main "$@"
