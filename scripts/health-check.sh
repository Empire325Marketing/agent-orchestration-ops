
#!/bin/bash

# 🏥 Health Check Script for Agent Orchestration Operations
# This script performs comprehensive health checks on the system

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/tmp/health-check-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Health check results
HEALTH_STATUS="healthy"
FAILED_CHECKS=()
WARNING_CHECKS=()

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    HEALTH_STATUS="unhealthy"
    FAILED_CHECKS+=("$1")
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
    if [[ "$HEALTH_STATUS" == "healthy" ]]; then
        HEALTH_STATUS="degraded"
    fi
    WARNING_CHECKS+=("$1")
}

# Default values
ENVIRONMENT="production"
TIMEOUT=30
VERBOSE=false
JSON_OUTPUT=false

# Usage function
usage() {
    cat << EOF
🏥 Agent Orchestration Operations Health Check Script

Usage: $0 [OPTIONS]

Options:
    -e, --environment ENV    Target environment (staging, production) [default: production]
    -t, --timeout SECONDS    Timeout for health checks [default: 30]
    -v, --verbose           Enable verbose output
    -j, --json              Output results in JSON format
    -h, --help              Show this help message

Examples:
    $0 --environment staging
    $0 --timeout 60 --verbose
    $0 --json > health-report.json

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -j|--json)
            JSON_OUTPUT=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Load environment configuration
load_environment() {
    local env_file="$PROJECT_ROOT/.env.$ENVIRONMENT"
    if [[ -f "$env_file" ]]; then
        source "$env_file"
        log "Loaded environment configuration for $ENVIRONMENT"
    else
        warning "Environment file not found: $env_file"
    fi
}

# Check system resources
check_system_resources() {
    log "🖥️ Checking system resources..."
    
    # Check disk space
    local disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ $disk_usage -gt 90 ]]; then
        error "Disk usage is critical: ${disk_usage}%"
    elif [[ $disk_usage -gt 80 ]]; then
        warning "Disk usage is high: ${disk_usage}%"
    else
        success "Disk usage is normal: ${disk_usage}%"
    fi
    
    # Check memory usage
    local memory_usage=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    local memory_int=${memory_usage%.*}
    if [[ $memory_int -gt 90 ]]; then
        error "Memory usage is critical: ${memory_usage}%"
    elif [[ $memory_int -gt 80 ]]; then
        warning "Memory usage is high: ${memory_usage}%"
    else
        success "Memory usage is normal: ${memory_usage}%"
    fi
    
    # Check CPU load
    local cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local cpu_cores=$(nproc)
    local load_percentage=$(echo "$cpu_load $cpu_cores" | awk '{printf "%.1f", ($1/$2)*100}')
    local load_int=${load_percentage%.*}
    
    if [[ $load_int -gt 90 ]]; then
        error "CPU load is critical: ${load_percentage}%"
    elif [[ $load_int -gt 80 ]]; then
        warning "CPU load is high: ${load_percentage}%"
    else
        success "CPU load is normal: ${load_percentage}%"
    fi
}

# Check network connectivity
check_network_connectivity() {
    log "🌐 Checking network connectivity..."
    
    # Check internet connectivity
    if ping -c 1 8.8.8.8 &> /dev/null; then
        success "Internet connectivity is working"
    else
        error "No internet connectivity"
    fi
    
    # Check DNS resolution
    if nslookup google.com &> /dev/null; then
        success "DNS resolution is working"
    else
        error "DNS resolution failed"
    fi
    
    # Check specific endpoints
    local endpoints=(
        "https://api.github.com"
        "https://registry.npmjs.org"
        "https://pypi.org"
    )
    
    for endpoint in "${endpoints[@]}"; do
        if curl -f -s --max-time "$TIMEOUT" "$endpoint" > /dev/null; then
            success "Endpoint reachable: $endpoint"
        else
            warning "Endpoint unreachable: $endpoint"
        fi
    done
}

# Check database connectivity
check_database() {
    log "🗄️ Checking database connectivity..."
    
    if [[ -n "${DATABASE_URL:-}" ]]; then
        # Extract database type from URL
        local db_type=$(echo "$DATABASE_URL" | cut -d':' -f1)
        
        case "$db_type" in
            postgresql|postgres)
                check_postgresql
                ;;
            mysql)
                check_mysql
                ;;
            mongodb)
                check_mongodb
                ;;
            redis)
                check_redis
                ;;
            *)
                warning "Unknown database type: $db_type"
                ;;
        esac
    else
        warning "No DATABASE_URL configured"
    fi
}

# Check PostgreSQL
check_postgresql() {
    if command -v psql &> /dev/null; then
        if psql "$DATABASE_URL" -c "SELECT 1;" &> /dev/null; then
            success "PostgreSQL connection successful"
            
            # Check database size
            local db_size=$(psql "$DATABASE_URL" -t -c "SELECT pg_size_pretty(pg_database_size(current_database()));" 2>/dev/null | xargs)
            if [[ -n "$db_size" ]]; then
                log "Database size: $db_size"
            fi
        else
            error "PostgreSQL connection failed"
        fi
    else
        warning "psql not installed, skipping PostgreSQL check"
    fi
}

# Check MySQL
check_mysql() {
    if command -v mysql &> /dev/null; then
        # Extract connection details from URL
        local mysql_cmd="mysql --connect-timeout=$TIMEOUT"
        
        if echo "SELECT 1;" | $mysql_cmd &> /dev/null; then
            success "MySQL connection successful"
        else
            error "MySQL connection failed"
        fi
    else
        warning "mysql not installed, skipping MySQL check"
    fi
}

# Check MongoDB
check_mongodb() {
    if command -v mongosh &> /dev/null || command -v mongo &> /dev/null; then
        local mongo_cmd="mongosh"
        if ! command -v mongosh &> /dev/null; then
            mongo_cmd="mongo"
        fi
        
        if echo "db.runCommand('ping')" | $mongo_cmd "$DATABASE_URL" --quiet &> /dev/null; then
            success "MongoDB connection successful"
        else
            error "MongoDB connection failed"
        fi
    else
        warning "MongoDB client not installed, skipping MongoDB check"
    fi
}

# Check Redis
check_redis() {
    if command -v redis-cli &> /dev/null; then
        local redis_host=$(echo "$DATABASE_URL" | sed 's/redis:\/\///' | cut -d':' -f1)
        local redis_port=$(echo "$DATABASE_URL" | sed 's/redis:\/\///' | cut -d':' -f2)
        
        if redis-cli -h "$redis_host" -p "$redis_port" ping | grep -q "PONG"; then
            success "Redis connection successful"
            
            # Check Redis memory usage
            local redis_memory=$(redis-cli -h "$redis_host" -p "$redis_port" info memory | grep "used_memory_human" | cut -d':' -f2 | tr -d '\r')
            if [[ -n "$redis_memory" ]]; then
                log "Redis memory usage: $redis_memory"
            fi
        else
            error "Redis connection failed"
        fi
    else
        warning "redis-cli not installed, skipping Redis check"
    fi
}

# Check application services
check_application_services() {
    log "🚀 Checking application services..."
    
    # Check if application is running
    local app_port="${PORT:-3000}"
    local health_endpoint="http://localhost:$app_port/health"
    
    if curl -f -s --max-time "$TIMEOUT" "$health_endpoint" > /dev/null; then
        success "Application health endpoint responding"
        
        # Get detailed health information
        local health_response=$(curl -s --max-time "$TIMEOUT" "$health_endpoint" 2>/dev/null)
        if [[ -n "$health_response" ]] && [[ "$VERBOSE" == true ]]; then
            log "Health response: $health_response"
        fi
    else
        error "Application health endpoint not responding"
    fi
    
    # Check specific service endpoints
    local endpoints=(
        "/api/v1/status"
        "/api/v1/agents"
        "/metrics"
    )
    
    for endpoint in "${endpoints[@]}"; do
        local url="http://localhost:$app_port$endpoint"
        if curl -f -s --max-time "$TIMEOUT" "$url" > /dev/null; then
            success "Endpoint responding: $endpoint"
        else
            warning "Endpoint not responding: $endpoint"
        fi
    done
}

# Check Docker services
check_docker_services() {
    log "🐳 Checking Docker services..."
    
    if command -v docker &> /dev/null; then
        # Check Docker daemon
        if docker info &> /dev/null; then
            success "Docker daemon is running"
            
            # Check running containers
            local running_containers=$(docker ps --format "table {{.Names}}\t{{.Status}}" | tail -n +2)
            if [[ -n "$running_containers" ]]; then
                success "Docker containers are running:"
                if [[ "$VERBOSE" == true ]]; then
                    echo "$running_containers" | while read -r line; do
                        log "  $line"
                    done
                fi
            else
                warning "No Docker containers are running"
            fi
            
            # Check Docker Compose services
            if command -v docker-compose &> /dev/null && [[ -f "$PROJECT_ROOT/docker-compose.yml" ]]; then
                cd "$PROJECT_ROOT"
                local compose_status=$(docker-compose ps --services --filter "status=running" 2>/dev/null)
                if [[ -n "$compose_status" ]]; then
                    success "Docker Compose services are running"
                else
                    warning "No Docker Compose services are running"
                fi
            fi
        else
            error "Docker daemon is not running"
        fi
    else
        log "Docker not installed, skipping Docker checks"
    fi
}

# Check SSL certificates
check_ssl_certificates() {
    log "🔒 Checking SSL certificates..."
    
    local domains=("${SSL_DOMAINS:-localhost}")
    
    for domain in "${domains[@]}"; do
        if [[ "$domain" != "localhost" ]]; then
            local cert_info=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)
            
            if [[ -n "$cert_info" ]]; then
                local expiry_date=$(echo "$cert_info" | grep "notAfter" | cut -d'=' -f2)
                local expiry_timestamp=$(date -d "$expiry_date" +%s 2>/dev/null)
                local current_timestamp=$(date +%s)
                local days_until_expiry=$(( (expiry_timestamp - current_timestamp) / 86400 ))
                
                if [[ $days_until_expiry -lt 7 ]]; then
                    error "SSL certificate for $domain expires in $days_until_expiry days"
                elif [[ $days_until_expiry -lt 30 ]]; then
                    warning "SSL certificate for $domain expires in $days_until_expiry days"
                else
                    success "SSL certificate for $domain is valid ($days_until_expiry days remaining)"
                fi
            else
                error "Could not retrieve SSL certificate for $domain"
            fi
        fi
    done
}

# Check log files
check_log_files() {
    log "📝 Checking log files..."
    
    local log_dirs=("/var/log" "$PROJECT_ROOT/logs" "/tmp")
    
    for log_dir in "${log_dirs[@]}"; do
        if [[ -d "$log_dir" ]]; then
            # Check for large log files
            local large_logs=$(find "$log_dir" -name "*.log" -size +100M 2>/dev/null)
            if [[ -n "$large_logs" ]]; then
                warning "Large log files found in $log_dir:"
                echo "$large_logs" | while read -r log_file; do
                    local size=$(du -h "$log_file" | cut -f1)
                    warning "  $log_file ($size)"
                done
            fi
            
            # Check for recent errors in logs
            local error_count=$(find "$log_dir" -name "*.log" -mtime -1 -exec grep -l -i "error\|exception\|fatal" {} \; 2>/dev/null | wc -l)
            if [[ $error_count -gt 0 ]]; then
                warning "$error_count log files contain recent errors in $log_dir"
            fi
        fi
    done
}

# Check security
check_security() {
    log "🛡️ Checking security..."
    
    # Check for running security tools
    if pgrep -f "fail2ban" > /dev/null; then
        success "fail2ban is running"
    else
        warning "fail2ban is not running"
    fi
    
    # Check firewall status
    if command -v ufw &> /dev/null; then
        local ufw_status=$(ufw status | head -1)
        if echo "$ufw_status" | grep -q "active"; then
            success "UFW firewall is active"
        else
            warning "UFW firewall is not active"
        fi
    fi
    
    # Check for suspicious processes
    local suspicious_processes=$(ps aux | grep -E "(nc|netcat|nmap|tcpdump)" | grep -v grep | wc -l)
    if [[ $suspicious_processes -gt 0 ]]; then
        warning "$suspicious_processes potentially suspicious processes found"
    fi
    
    # Check file permissions on sensitive files
    local sensitive_files=(".env" ".env.production" "config/database.yml")
    for file in "${sensitive_files[@]}"; do
        local file_path="$PROJECT_ROOT/$file"
        if [[ -f "$file_path" ]]; then
            local perms=$(stat -c "%a" "$file_path")
            if [[ "$perms" != "600" ]] && [[ "$perms" != "400" ]]; then
                warning "Sensitive file $file has permissive permissions: $perms"
            else
                success "Sensitive file $file has secure permissions: $perms"
            fi
        fi
    done
}

# Generate health report
generate_health_report() {
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local uptime=$(uptime -p)
    local load_avg=$(uptime | awk -F'load average:' '{print $2}')
    
    if [[ "$JSON_OUTPUT" == true ]]; then
        # Generate JSON report
        cat << EOF
{
  "timestamp": "$timestamp",
  "environment": "$ENVIRONMENT",
  "status": "$HEALTH_STATUS",
  "uptime": "$uptime",
  "load_average": "$load_avg",
  "failed_checks": $(printf '%s\n' "${FAILED_CHECKS[@]}" | jq -R . | jq -s .),
  "warning_checks": $(printf '%s\n' "${WARNING_CHECKS[@]}" | jq -R . | jq -s .),
  "system": {
    "disk_usage": "$(df / | awk 'NR==2 {print $5}')",
    "memory_usage": "$(free | awk 'NR==2{printf "%.1f%%", $3*100/$2}')",
    "cpu_load": "$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')"
  }
}
EOF
    else
        # Generate human-readable report
        echo
        echo "🏥 Health Check Report"
        echo "====================="
        echo "Timestamp: $timestamp"
        echo "Environment: $ENVIRONMENT"
        echo "Overall Status: $HEALTH_STATUS"
        echo "System Uptime: $uptime"
        echo "Load Average: $load_avg"
        echo
        
        if [[ ${#FAILED_CHECKS[@]} -gt 0 ]]; then
            echo "❌ Failed Checks (${#FAILED_CHECKS[@]}):"
            printf '%s\n' "${FAILED_CHECKS[@]}" | sed 's/^/  - /'
            echo
        fi
        
        if [[ ${#WARNING_CHECKS[@]} -gt 0 ]]; then
            echo "⚠️ Warning Checks (${#WARNING_CHECKS[@]}):"
            printf '%s\n' "${WARNING_CHECKS[@]}" | sed 's/^/  - /'
            echo
        fi
        
        case "$HEALTH_STATUS" in
            healthy)
                echo "✅ All systems are healthy!"
                ;;
            degraded)
                echo "⚠️ System is degraded but operational"
                ;;
            unhealthy)
                echo "❌ System is unhealthy and requires attention"
                ;;
        esac
    fi
}

# Main health check function
main() {
    if [[ "$JSON_OUTPUT" != true ]]; then
        log "🏥 Starting comprehensive health check for $ENVIRONMENT environment"
        log "📝 Log file: $LOG_FILE"
    fi
    
    # Load environment configuration
    load_environment
    
    # Run all health checks
    check_system_resources
    check_network_connectivity
    check_database
    check_application_services
    check_docker_services
    check_ssl_certificates
    check_log_files
    check_security
    
    # Generate and display report
    generate_health_report
    
    # Exit with appropriate code
    case "$HEALTH_STATUS" in
        healthy)
            exit 0
            ;;
        degraded)
            exit 1
            ;;
        unhealthy)
            exit 2
            ;;
    esac
}

# Run main function
main "$@"
