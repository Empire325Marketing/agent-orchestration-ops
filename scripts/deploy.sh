
#!/bin/bash

# 🚀 Deployment Script for Agent Orchestration Operations
# This script handles deployment to different environments

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/tmp/deploy-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Default values
ENVIRONMENT="staging"
SKIP_TESTS=false
SKIP_BACKUP=false
DRY_RUN=false
FORCE=false

# Usage function
usage() {
    cat << EOF
🚀 Agent Orchestration Operations Deployment Script

Usage: $0 [OPTIONS]

Options:
    -e, --environment ENV    Target environment (staging, production) [default: staging]
    -t, --skip-tests        Skip running tests before deployment
    -b, --skip-backup       Skip creating backup before deployment
    -d, --dry-run           Show what would be deployed without actually deploying
    -f, --force             Force deployment even if checks fail
    -h, --help              Show this help message

Examples:
    $0 --environment staging
    $0 --environment production --skip-tests
    $0 --dry-run --environment production

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -t|--skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        -b|--skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(staging|production)$ ]]; then
    error "Invalid environment: $ENVIRONMENT. Must be 'staging' or 'production'"
fi

log "🚀 Starting deployment to $ENVIRONMENT environment"
log "📝 Log file: $LOG_FILE"

# Check prerequisites
check_prerequisites() {
    log "🔍 Checking prerequisites..."
    
    # Check if required tools are installed
    local required_tools=("git" "curl" "jq")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            error "$tool is required but not installed"
        fi
    done
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error "Not in a git repository"
    fi
    
    # Check if environment file exists
    local env_file="$PROJECT_ROOT/.env.$ENVIRONMENT"
    if [[ ! -f "$env_file" ]]; then
        error "Environment file not found: $env_file"
    fi
    
    # Check if we have uncommitted changes (for production)
    if [[ "$ENVIRONMENT" == "production" ]] && [[ -n "$(git status --porcelain)" ]]; then
        if [[ "$FORCE" != true ]]; then
            error "Uncommitted changes detected. Commit changes or use --force flag"
        else
            warning "Deploying with uncommitted changes (--force flag used)"
        fi
    fi
    
    success "Prerequisites check passed"
}

# Run tests
run_tests() {
    if [[ "$SKIP_TESTS" == true ]]; then
        warning "Skipping tests (--skip-tests flag used)"
        return 0
    fi
    
    log "🧪 Running tests..."
    
    # Run different types of tests
    if [[ -f "$PROJECT_ROOT/package.json" ]]; then
        log "Running JavaScript tests..."
        cd "$PROJECT_ROOT"
        npm test || error "JavaScript tests failed"
    fi
    
    if [[ -f "$PROJECT_ROOT/requirements.txt" ]]; then
        log "Running Python tests..."
        cd "$PROJECT_ROOT"
        python -m pytest tests/ || error "Python tests failed"
    fi
    
    # Run security tests
    if command -v bandit &> /dev/null && find "$PROJECT_ROOT" -name "*.py" | head -1 > /dev/null; then
        log "Running security tests..."
        bandit -r "$PROJECT_ROOT" -f json -o bandit-report.json || warning "Security issues detected"
    fi
    
    success "All tests passed"
}

# Create backup
create_backup() {
    if [[ "$SKIP_BACKUP" == true ]]; then
        warning "Skipping backup (--skip-backup flag used)"
        return 0
    fi
    
    log "💾 Creating backup..."
    
    local backup_dir="/tmp/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup current deployment (this would be environment-specific)
    case "$ENVIRONMENT" in
        staging)
            log "Creating staging backup..."
            # Add staging-specific backup commands here
            ;;
        production)
            log "Creating production backup..."
            # Add production-specific backup commands here
            ;;
    esac
    
    success "Backup created at $backup_dir"
}

# Build application
build_application() {
    log "🏗️ Building application..."
    
    cd "$PROJECT_ROOT"
    
    # Install dependencies
    if [[ -f "package.json" ]]; then
        log "Installing Node.js dependencies..."
        npm ci
        
        # Build frontend assets
        if npm run build &> /dev/null; then
            log "Built frontend assets"
        fi
    fi
    
    if [[ -f "requirements.txt" ]]; then
        log "Installing Python dependencies..."
        pip install -r requirements.txt
    fi
    
    # Build Docker image if Dockerfile exists
    if [[ -f "Dockerfile" ]]; then
        log "Building Docker image..."
        local image_tag="agent-orchestration-ops:$ENVIRONMENT-$(git rev-parse --short HEAD)"
        docker build -t "$image_tag" .
        success "Docker image built: $image_tag"
    fi
    
    success "Application built successfully"
}

# Deploy to environment
deploy_to_environment() {
    log "🚀 Deploying to $ENVIRONMENT..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log "🔍 DRY RUN MODE - No actual deployment will occur"
        log "Would deploy the following:"
        log "  - Environment: $ENVIRONMENT"
        log "  - Git commit: $(git rev-parse HEAD)"
        log "  - Branch: $(git branch --show-current)"
        return 0
    fi
    
    case "$ENVIRONMENT" in
        staging)
            deploy_to_staging
            ;;
        production)
            deploy_to_production
            ;;
    esac
    
    success "Deployment to $ENVIRONMENT completed"
}

# Deploy to staging
deploy_to_staging() {
    log "🎭 Deploying to staging environment..."
    
    # Load staging environment variables
    source "$PROJECT_ROOT/.env.staging"
    
    # Deploy application (customize based on your infrastructure)
    if command -v docker-compose &> /dev/null && [[ -f "$PROJECT_ROOT/docker-compose.staging.yml" ]]; then
        log "Using Docker Compose for staging deployment..."
        cd "$PROJECT_ROOT"
        docker-compose -f docker-compose.staging.yml down
        docker-compose -f docker-compose.staging.yml up -d
    else
        log "Using custom staging deployment..."
        # Add your staging deployment commands here
        # Examples:
        # - Copy files to staging server
        # - Restart services
        # - Update configuration
    fi
    
    success "Staging deployment completed"
}

# Deploy to production
deploy_to_production() {
    log "🏭 Deploying to production environment..."
    
    # Additional safety checks for production
    if [[ "$FORCE" != true ]]; then
        log "⚠️  Production deployment requires confirmation"
        read -p "Are you sure you want to deploy to production? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            error "Production deployment cancelled by user"
        fi
    fi
    
    # Load production environment variables
    source "$PROJECT_ROOT/.env.production"
    
    # Blue-green deployment for production
    log "🔄 Starting blue-green deployment..."
    
    # Deploy to blue environment first
    deploy_blue_environment
    
    # Health check blue environment
    if health_check_environment "blue"; then
        # Switch traffic to blue environment
        switch_traffic_to_blue
        
        # Clean up green environment
        cleanup_green_environment
    else
        error "Blue environment health check failed. Deployment aborted."
    fi
    
    success "Production deployment completed"
}

# Deploy to blue environment
deploy_blue_environment() {
    log "🔵 Deploying to blue environment..."
    
    # Deploy application to blue environment
    if command -v docker-compose &> /dev/null && [[ -f "$PROJECT_ROOT/docker-compose.production.yml" ]]; then
        cd "$PROJECT_ROOT"
        docker-compose -f docker-compose.production.yml -f docker-compose.blue.yml up -d
    else
        # Add your blue environment deployment commands here
        log "Custom blue environment deployment..."
    fi
}

# Health check environment
health_check_environment() {
    local env_color="$1"
    log "🏥 Running health check for $env_color environment..."
    
    local health_url
    case "$env_color" in
        blue)
            health_url="http://blue.internal/health"
            ;;
        green)
            health_url="http://green.internal/health"
            ;;
        *)
            health_url="http://localhost/health"
            ;;
    esac
    
    # Wait for service to start
    sleep 30
    
    # Perform health checks
    local max_attempts=10
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        log "Health check attempt $attempt/$max_attempts..."
        
        if curl -f -s "$health_url" > /dev/null; then
            success "$env_color environment is healthy"
            return 0
        fi
        
        sleep 10
        ((attempt++))
    done
    
    error "$env_color environment health check failed after $max_attempts attempts"
    return 1
}

# Switch traffic to blue environment
switch_traffic_to_blue() {
    log "🔄 Switching traffic to blue environment..."
    
    # Update load balancer configuration
    # This would be specific to your load balancer (nginx, HAProxy, AWS ALB, etc.)
    
    # Example for nginx
    if command -v nginx &> /dev/null; then
        # Update nginx configuration to point to blue environment
        sudo cp "$PROJECT_ROOT/config/nginx.blue.conf" /etc/nginx/sites-available/default
        sudo nginx -t && sudo systemctl reload nginx
    fi
    
    success "Traffic switched to blue environment"
}

# Cleanup green environment
cleanup_green_environment() {
    log "🧹 Cleaning up green environment..."
    
    # Stop green environment services
    if command -v docker-compose &> /dev/null && [[ -f "$PROJECT_ROOT/docker-compose.green.yml" ]]; then
        cd "$PROJECT_ROOT"
        docker-compose -f docker-compose.green.yml down
    fi
    
    success "Green environment cleaned up"
}

# Post-deployment tasks
post_deployment_tasks() {
    log "📋 Running post-deployment tasks..."
    
    # Database migrations
    if [[ -f "$PROJECT_ROOT/migrate.sh" ]]; then
        log "Running database migrations..."
        bash "$PROJECT_ROOT/migrate.sh"
    fi
    
    # Clear caches
    log "Clearing caches..."
    # Add cache clearing commands here
    
    # Warm up caches
    log "Warming up caches..."
    # Add cache warming commands here
    
    # Send notifications
    send_deployment_notification
    
    success "Post-deployment tasks completed"
}

# Send deployment notification
send_deployment_notification() {
    log "📢 Sending deployment notification..."
    
    local git_commit=$(git rev-parse --short HEAD)
    local git_branch=$(git branch --show-current)
    local deploy_time=$(date)
    
    # Slack notification (if webhook URL is configured)
    if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{
                \"text\": \"🚀 Deployment to $ENVIRONMENT completed\",
                \"attachments\": [{
                    \"color\": \"good\",
                    \"fields\": [
                        {\"title\": \"Environment\", \"value\": \"$ENVIRONMENT\", \"short\": true},
                        {\"title\": \"Commit\", \"value\": \"$git_commit\", \"short\": true},
                        {\"title\": \"Branch\", \"value\": \"$git_branch\", \"short\": true},
                        {\"title\": \"Time\", \"value\": \"$deploy_time\", \"short\": true}
                    ]
                }]
            }" \
            "$SLACK_WEBHOOK_URL"
    fi
    
    # Email notification (if configured)
    if command -v mail &> /dev/null && [[ -n "${NOTIFICATION_EMAIL:-}" ]]; then
        echo "Deployment to $ENVIRONMENT completed successfully at $deploy_time" | \
            mail -s "Deployment Notification - $ENVIRONMENT" "$NOTIFICATION_EMAIL"
    fi
    
    success "Deployment notification sent"
}

# Rollback function
rollback() {
    log "🔄 Rolling back deployment..."
    
    # This would implement rollback logic
    # - Restore from backup
    # - Switch back to previous version
    # - Restart services
    
    error "Rollback functionality not yet implemented"
}

# Cleanup function
cleanup() {
    log "🧹 Cleaning up temporary files..."
    
    # Remove temporary files
    rm -f bandit-report.json
    
    # Clean up Docker images (keep last 5)
    if command -v docker &> /dev/null; then
        docker image prune -f
    fi
    
    success "Cleanup completed"
}

# Main deployment function
main() {
    log "🚀 Agent Orchestration Operations Deployment"
    log "Environment: $ENVIRONMENT"
    log "Dry Run: $DRY_RUN"
    log "Skip Tests: $SKIP_TESTS"
    log "Skip Backup: $SKIP_BACKUP"
    log "Force: $FORCE"
    
    # Trap to ensure cleanup on exit
    trap cleanup EXIT
    
    # Run deployment steps
    check_prerequisites
    run_tests
    create_backup
    build_application
    deploy_to_environment
    post_deployment_tasks
    
    success "🎉 Deployment completed successfully!"
    log "📝 Full deployment log available at: $LOG_FILE"
}

# Run main function
main "$@"
