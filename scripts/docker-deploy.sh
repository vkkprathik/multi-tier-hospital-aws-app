#!/bin/bash
# Docker Deployment Script for Hospital App
# This script simplifies Docker setup and deployment

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default values
COMMAND="${1:-help}"
ENVIRONMENT="${2:-development}"

# Functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker Desktop from https://www.docker.com"
        exit 1
    fi
    print_success "Docker is installed"
}

check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Desktop."
        exit 1
    fi
    print_success "Docker Compose is installed"
}

setup_env() {
    print_header "Setting Up Environment"
    
    if [ ! -f "$PROJECT_DIR/.env" ]; then
        print_info "Creating .env file from .env.example"
        cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
        print_success ".env file created"
        print_warning "Please update .env with your configuration"
    else
        print_success ".env file already exists"
    fi
}

build() {
    print_header "Building Docker Images"
    check_docker
    
    cd "$PROJECT_DIR"
    docker-compose build --no-cache
    print_success "Docker images built successfully"
}

start() {
    print_header "Starting Docker Services"
    check_docker
    check_docker_compose
    setup_env
    
    cd "$PROJECT_DIR"
    docker-compose up -d
    
    print_success "Docker services started"
    print_info "Waiting for services to be ready..."
    sleep 5
    
    # Check if services are running
    if docker-compose ps | grep -q "Up"; then
        print_success "All services are running"
        print_info "Application URL: http://localhost:5000"
        print_info "phpMyAdmin URL: http://localhost:8080"
    else
        print_error "Failed to start services"
        docker-compose logs
        exit 1
    fi
}

stop() {
    print_header "Stopping Docker Services"
    cd "$PROJECT_DIR"
    docker-compose down
    print_success "Docker services stopped"
}

restart() {
    print_header "Restarting Docker Services"
    stop
    sleep 2
    start
}

logs() {
    print_header "Viewing Docker Logs"
    cd "$PROJECT_DIR"
    
    if [ -z "$2" ]; then
        docker-compose logs -f
    else
        docker-compose logs -f "$2"
    fi
}

status() {
    print_header "Docker Services Status"
    cd "$PROJECT_DIR"
    docker-compose ps
    
    print_info "Container Details:"
    docker-compose exec -T app curl -s http://localhost:5000/health 2>/dev/null && print_success "App is healthy" || print_warning "App health check failed"
}

shell() {
    print_header "Opening Shell in App Container"
    cd "$PROJECT_DIR"
    docker-compose exec app bash
}

clean() {
    print_header "Cleaning Up Docker Resources"
    
    read -p "Are you sure you want to remove all containers and volumes? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$PROJECT_DIR"
        docker-compose down -v
        print_success "Cleanup completed"
    else
        print_warning "Cleanup cancelled"
    fi
}

backup_db() {
    print_header "Backing Up Database"
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$PROJECT_DIR/backups/hospital_backup_${TIMESTAMP}.sql"
    
    mkdir -p "$PROJECT_DIR/backups"
    
    cd "$PROJECT_DIR"
    docker-compose exec -T database mysqldump -u hospitaluser -ppassword123 hospital > "$BACKUP_FILE"
    
    print_success "Database backed up to $BACKUP_FILE"
}

restore_db() {
    print_header "Restoring Database"
    
    if [ -z "$2" ]; then
        print_error "Please provide backup file path: ./scripts/deploy.sh restore_db <backup_file>"
        exit 1
    fi
    
    BACKUP_FILE="$2"
    
    if [ ! -f "$BACKUP_FILE" ]; then
        print_error "Backup file not found: $BACKUP_FILE"
        exit 1
    fi
    
    cd "$PROJECT_DIR"
    docker-compose exec -T database mysql -u hospitaluser -ppassword123 hospital < "$BACKUP_FILE"
    
    print_success "Database restored from $BACKUP_FILE"
}

health_check() {
    print_header "Performing Health Checks"
    
    cd "$PROJECT_DIR"
    
    echo -n "Checking Docker daemon... "
    docker ps > /dev/null && print_success "Docker daemon running" || print_error "Docker daemon not running"
    
    echo -n "Checking Docker services... "
    docker-compose ps --services | wc -l > /dev/null && print_success "Docker Compose working" || print_error "Docker Compose failed"
    
    echo -n "Checking application... "
    curl -s http://localhost:5000/ > /dev/null && print_success "App responding" || print_warning "App not responding"
    
    echo -n "Checking database... "
    docker-compose exec -T database mysqladmin ping -h localhost -u hospitaluser -ppassword123 > /dev/null 2>&1 && print_success "Database responding" || print_warning "Database not responding"
}

show_help() {
    cat << EOF
${BLUE}Hospital App Docker Deployment Script${NC}

Usage: $0 <command> [options]

Commands:
    help            Show this help message
    check          Check Docker and Docker Compose installation
    setup          Setup environment variables
    build          Build Docker images
    start          Start Docker services
    stop           Stop Docker services
    restart        Restart Docker services
    status         Show services status
    logs [service] View logs (use 'app' or 'database' for specific service)
    shell          Open bash shell in app container
    clean          Remove all containers and volumes (WARNING: destructive)
    backup         Backup database
    restore <file> Restore database from backup file
    health         Perform system health checks

Examples:
    $0 start                    # Start all services
    $0 logs app                 # View app logs
    $0 shell                    # Access app container
    $0 backup                   # Backup database
    $0 restore backups/backup.sql  # Restore database

${YELLOW}Requirements:${NC}
    - Docker Desktop
    - Docker Compose
    - Bash shell (or use .ps1 script for PowerShell)

${GREEN}Documentation:${NC}
    See DOCKER_DEPLOYMENT.md for detailed information

EOF
}

# Main script logic
case "$COMMAND" in
    help)
        show_help
        ;;
    check)
        check_docker
        check_docker_compose
        ;;
    setup)
        setup_env
        ;;
    build)
        build
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    logs)
        logs "$@"
        ;;
    shell)
        shell
        ;;
    clean)
        clean
        ;;
    backup)
        backup_db
        ;;
    restore)
        restore_db "$@"
        ;;
    health)
        health_check
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac
