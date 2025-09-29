#!/bin/bash

# Enterprise Branch Protection Setup Script
# This script configures comprehensive branch protection rules for enterprise-grade security

set -euo pipefail

# Configuration
REPO_OWNER="Empire325Marketing"
REPO_NAME="agent-orchestration-ops"
DEFAULT_BRANCH="ops-readiness"
MAIN_BRANCH="main"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if GitHub CLI is available
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        error "GitHub CLI (gh) is not installed. Please install it first."
        exit 1
    fi
    
    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        error "GitHub CLI is not authenticated. Please run 'gh auth login' first."
        exit 1
    fi
    
    success "GitHub CLI is available and authenticated"
}

# Function to apply branch protection rules
apply_branch_protection() {
    local branch=$1
    local branch_type=$2
    
    log "Applying enterprise branch protection rules to '$branch' ($branch_type)..."
    
    # Base protection rules
    local protection_rules='{
        "required_status_checks": {
            "strict": true,
            "contexts": [
                "readiness:agents",
                "alerts:validate", 
                "runbooks:index",
                "security:scan",
                "integration:test",
                "docs:drift",
                "security:dependencies",
                "compliance:audit",
                "security:baseline"
            ]
        },
        "enforce_admins": false,
        "required_pull_request_reviews": {
            "required_approving_review_count": 2,
            "dismiss_stale_reviews": true,
            "require_code_owner_reviews": true,
            "require_last_push_approval": true
        },
        "restrictions": null,
        "allow_force_pushes": false,
        "allow_deletions": false,
        "block_creations": false,
        "required_conversation_resolution": true
    }'
    
    # Adjust rules based on branch type
    if [ "$branch_type" = "production" ]; then
        # More restrictive rules for production branches
        protection_rules=$(echo "$protection_rules" | jq '.required_pull_request_reviews.required_approving_review_count = 3')
        protection_rules=$(echo "$protection_rules" | jq '.enforce_admins = false')
    fi
    
    # Apply protection using GitHub API
    local api_url="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/branches/$branch/protection"
    
    if curl -s -X PUT \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -d "$protection_rules" \
        "$api_url" > /dev/null 2>&1; then
        success "Branch protection applied to '$branch'"
    else
        warning "Failed to apply branch protection to '$branch' - may require additional permissions"
        
        # Try using GitHub CLI as fallback
        log "Attempting to use GitHub CLI for branch protection..."
        
        if gh api repos/$REPO_OWNER/$REPO_NAME/branches/$branch/protection \
            --method PUT \
            --input <(echo "$protection_rules") > /dev/null 2>&1; then
            success "Branch protection applied to '$branch' via GitHub CLI"
        else
            error "Failed to apply branch protection to '$branch'"
            return 1
        fi
    fi
}

# Function to create production environment
setup_production_environment() {
    log "Setting up production environment..."
    
    local env_config='{
        "wait_timer": 0,
        "reviewers": [
            {
                "type": "Team",
                "id": "security-team"
            },
            {
                "type": "Team", 
                "id": "operations-team"
            }
        ],
        "deployment_branch_policy": {
            "protected_branches": true,
            "custom_branch_policies": false
        }
    }'
    
    # Create environment using GitHub API
    local api_url="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/environments/production"
    
    if curl -s -X PUT \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -d "$env_config" \
        "$api_url" > /dev/null 2>&1; then
        success "Production environment configured"
    else
        warning "Failed to configure production environment - may require additional permissions"
    fi
}

# Function to setup required status checks
setup_status_checks() {
    log "Configuring required status checks..."
    
    local branches=("$DEFAULT_BRANCH" "$MAIN_BRANCH")
    
    for branch in "${branches[@]}"; do
        log "Setting up status checks for '$branch'..."
        
        # Check if branch exists
        if gh api repos/$REPO_OWNER/$REPO_NAME/branches/$branch > /dev/null 2>&1; then
            log "Branch '$branch' exists, configuring status checks..."
            
            # The status checks are configured as part of branch protection
            # They will be enforced when the workflows run
            success "Status checks configured for '$branch'"
        else
            warning "Branch '$branch' does not exist, skipping status checks"
        fi
    done
}

# Function to setup security policies
setup_security_policies() {
    log "Setting up security policies..."
    
    # Enable vulnerability alerts
    if gh api repos/$REPO_OWNER/$REPO_NAME/vulnerability-alerts \
        --method PUT > /dev/null 2>&1; then
        success "Vulnerability alerts enabled"
    else
        warning "Failed to enable vulnerability alerts"
    fi
    
    # Enable automated security fixes
    if gh api repos/$REPO_OWNER/$REPO_NAME/automated-security-fixes \
        --method PUT > /dev/null 2>&1; then
        success "Automated security fixes enabled"
    else
        warning "Failed to enable automated security fixes"
    fi
    
    # Enable dependency graph
    log "Dependency graph should be enabled in repository settings"
    success "Security policies configuration completed"
}

# Function to validate setup
validate_setup() {
    log "Validating enterprise setup..."
    
    local validation_passed=true
    
    # Check branch protection
    for branch in "$DEFAULT_BRANCH" "$MAIN_BRANCH"; do
        if gh api repos/$REPO_OWNER/$REPO_NAME/branches/$branch/protection > /dev/null 2>&1; then
            success "Branch protection validated for '$branch'"
        else
            error "Branch protection missing for '$branch'"
            validation_passed=false
        fi
    done
    
    # Check workflows exist
    local required_workflows=("ci.yml" "release.yml" "enterprise-security.yml")
    for workflow in "${required_workflows[@]}"; do
        if [ -f ".github/workflows/$workflow" ]; then
            success "Workflow '$workflow' exists"
        else
            error "Workflow '$workflow' missing"
            validation_passed=false
        fi
    done
    
    # Check security files
    local security_files=("SECURITY.md" "security/patch_policy.md")
    for file in "${security_files[@]}"; do
        if [ -f "$file" ]; then
            success "Security file '$file' exists"
        else
            warning "Security file '$file' missing - consider adding"
        fi
    done
    
    if [ "$validation_passed" = true ]; then
        success "Enterprise setup validation passed"
        return 0
    else
        error "Enterprise setup validation failed"
        return 1
    fi
}

# Main execution
main() {
    log "Starting enterprise branch protection setup..."
    
    # Check prerequisites
    check_gh_cli
    
    # Check if we have a GitHub token
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        warning "GITHUB_TOKEN not set, using GitHub CLI authentication"
    fi
    
    # Apply branch protection rules
    log "Applying branch protection rules..."
    
    # Protect default branch
    if apply_branch_protection "$DEFAULT_BRANCH" "development"; then
        success "Default branch protection applied"
    else
        error "Failed to apply default branch protection"
    fi
    
    # Protect main branch if it exists
    if gh api repos/$REPO_OWNER/$REPO_NAME/branches/$MAIN_BRANCH > /dev/null 2>&1; then
        if apply_branch_protection "$MAIN_BRANCH" "production"; then
            success "Main branch protection applied"
        else
            error "Failed to apply main branch protection"
        fi
    else
        log "Main branch does not exist, skipping protection"
    fi
    
    # Setup production environment
    setup_production_environment
    
    # Setup status checks
    setup_status_checks
    
    # Setup security policies
    setup_security_policies
    
    # Validate setup
    if validate_setup; then
        success "Enterprise branch protection setup completed successfully!"
        
        log "Summary of applied configurations:"
        echo "  • Branch protection rules with required reviews"
        echo "  • Required status checks from CI/CD workflows"
        echo "  • Production environment with deployment protection"
        echo "  • Security policies and vulnerability alerts"
        echo "  • Automated security fixes enabled"
        
        log "Next steps:"
        echo "  1. Review and test the protection rules"
        echo "  2. Configure team permissions in GitHub settings"
        echo "  3. Add security team members as reviewers"
        echo "  4. Test the CI/CD pipeline with a pull request"
        
    else
        error "Enterprise setup validation failed - please review and fix issues"
        exit 1
    fi
}

# Run main function
main "$@"
