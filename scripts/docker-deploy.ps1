# Docker Deployment Script for Hospital App (PowerShell)
# This script simplifies Docker setup and deployment on Windows

param(
    [string]$Command = "help",
    [string]$Argument = ""
)

# Color functions for output
function Print-Header {
    param([string]$Message)
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
}

function Print-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Print-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Print-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Print-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

# Check if Docker is installed
function Check-Docker {
    if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
        Print-Error "Docker is not installed. Please install Docker Desktop from https://www.docker.com"
        exit 1
    }
    Print-Success "Docker is installed"
}

# Check if Docker Compose is installed
function Check-DockerCompose {
    if (!(Get-Command docker-compose -ErrorAction SilentlyContinue)) {
        Print-Error "Docker Compose is not installed. Please install Docker Desktop."
        exit 1
    }
    Print-Success "Docker Compose is installed"
}

# Setup environment
function Setup-Env {
    Print-Header "Setting Up Environment"
    
    $EnvPath = "$(Get-Location)\.env"
    $EnvExamplePath = "$(Get-Location)\.env.example"
    
    if (!(Test-Path $EnvPath)) {
        if (Test-Path $EnvExamplePath) {
            Copy-Item $EnvExamplePath $EnvPath
            Print-Success ".env file created from .env.example"
            Print-Warning "Please update .env with your configuration"
        } else {
            Print-Error ".env.example not found"
        }
    } else {
        Print-Success ".env file already exists"
    }
}

# Build Docker images
function Build-Images {
    Print-Header "Building Docker Images"
    Check-Docker
    
    docker-compose build --no-cache
    
    if ($LASTEXITCODE -eq 0) {
        Print-Success "Docker images built successfully"
    } else {
        Print-Error "Failed to build Docker images"
        exit 1
    }
}

# Start services
function Start-Services {
    Print-Header "Starting Docker Services"
    Check-Docker
    Check-DockerCompose
    Setup-Env
    
    docker-compose up -d
    
    if ($LASTEXITCODE -eq 0) {
        Print-Success "Docker services started"
        Print-Info "Waiting for services to be ready..."
        Start-Sleep -Seconds 5
        
        Print-Success "All services are running"
        Print-Info "Application URL: http://localhost:5000"
        Print-Info "phpMyAdmin URL: http://localhost:8080"
    } else {
        Print-Error "Failed to start services"
        docker-compose logs
        exit 1
    }
}

# Stop services
function Stop-Services {
    Print-Header "Stopping Docker Services"
    docker-compose down
    Print-Success "Docker services stopped"
}

# Restart services
function Restart-Services {
    Print-Header "Restarting Docker Services"
    Stop-Services
    Start-Sleep -Seconds 2
    Start-Services
}

# View logs
function View-Logs {
    Print-Header "Viewing Docker Logs"
    
    if ($Argument) {
        docker-compose logs -f $Argument
    } else {
        docker-compose logs -f
    }
}

# Show status
function Show-Status {
    Print-Header "Docker Services Status"
    docker-compose ps
    
    Print-Info "Service Details:"
    try {
        $AppHealth = curl.exe -s http://localhost:5000/ 2>$null
        if ($AppHealth) {
            Print-Success "App is responding"
        }
    } catch {
        Print-Warning "App health check failed"
    }
}

# Open shell in container
function Open-Shell {
    Print-Header "Opening Shell in App Container"
    docker-compose exec app bash
}

# Clean up resources
function Clean-Resources {
    Print-Header "Cleaning Up Docker Resources"
    
    $Response = Read-Host "Are you sure you want to remove all containers and volumes? (y/n)"
    if ($Response -eq 'y' -or $Response -eq 'Y') {
        docker-compose down -v
        Print-Success "Cleanup completed"
    } else {
        Print-Warning "Cleanup cancelled"
    }
}

# Backup database
function Backup-Database {
    Print-Header "Backing Up Database"
    
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $BackupDir = "$(Get-Location)\backups"
    $BackupFile = "$BackupDir\hospital_backup_${Timestamp}.sql"
    
    if (!(Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }
    
    docker-compose exec -T database mysqldump -u hospitaluser -ppassword123 hospital | Out-File -Encoding UTF8 $BackupFile
    
    Print-Success "Database backed up to $BackupFile"
}

# Restore database
function Restore-Database {
    Print-Header "Restoring Database"
    
    if (!$Argument) {
        Print-Error "Please provide backup file path"
        exit 1
    }
    
    if (!(Test-Path $Argument)) {
        Print-Error "Backup file not found: $Argument"
        exit 1
    }
    
    Get-Content $Argument | docker-compose exec -T database mysql -u hospitaluser -ppassword123 hospital
    
    Print-Success "Database restored from $Argument"
}

# Health check
function Health-Check {
    Print-Header "Performing Health Checks"
    
    Write-Host -NoNewline "Checking Docker daemon... "
    $DockerStatus = docker ps 2>$null
    if ($DockerStatus) {
        Print-Success "Docker daemon running"
    } else {
        Print-Error "Docker daemon not running"
    }
    
    Write-Host -NoNewline "Checking Docker services... "
    $ComposeStatus = docker-compose ps 2>$null
    if ($ComposeStatus) {
        Print-Success "Docker Compose working"
    } else {
        Print-Error "Docker Compose failed"
    }
    
    Write-Host -NoNewline "Checking application... "
    try {
        curl.exe -s http://localhost:5000/ | Out-Null
        Print-Success "App responding"
    } catch {
        Print-Warning "App not responding"
    }
    
    Write-Host -NoNewline "Checking database... "
    $DbStatus = docker-compose exec -T database mysqladmin ping -h localhost -u hospitaluser -ppassword123 2>$null
    if ($DbStatus) {
        Print-Success "Database responding"
    } else {
        Print-Warning "Database not responding"
    }
}

# Show help
function Show-Help {
    $HelpText = @"
Hospital App Docker Deployment Script (PowerShell)

Usage: .\docker-deploy.ps1 -Command <command> [-Argument <argument>]

Commands:
    help            Show this help message
    check           Check Docker and Docker Compose installation
    setup           Setup environment variables
    build           Build Docker images
    start           Start Docker services
    stop            Stop Docker services
    restart         Restart Docker services
    status          Show services status
    logs            View logs (optionally specify service: app or database)
    shell           Open PowerShell in app container
    clean           Remove all containers and volumes (WARNING: destructive)
    backup          Backup database
    restore         Restore database from backup file
    health          Perform system health checks

Examples:
    .\docker-deploy.ps1 -Command start
    .\docker-deploy.ps1 -Command logs -Argument app
    .\docker-deploy.ps1 -Command backup
    .\docker-deploy.ps1 -Command restore -Argument backups\hospital_backup_20240101_120000.sql

Requirements:
    - Docker Desktop
    - PowerShell 5.0+

Documentation:
    See DOCKER_DEPLOYMENT.md for detailed information
"@
    Write-Host $HelpText -ForegroundColor Cyan
}

# Main script logic
switch ($Command.ToLower()) {
    "help" {
        Show-Help
    }
    "check" {
        Check-Docker
        Check-DockerCompose
    }
    "setup" {
        Setup-Env
    }
    "build" {
        Build-Images
    }
    "start" {
        Start-Services
    }
    "stop" {
        Stop-Services
    }
    "restart" {
        Restart-Services
    }
    "status" {
        Show-Status
    }
    "logs" {
        View-Logs
    }
    "shell" {
        Open-Shell
    }
    "clean" {
        Clean-Resources
    }
    "backup" {
        Backup-Database
    }
    "restore" {
        Restore-Database
    }
    "health" {
        Health-Check
    }
    default {
        Print-Error "Unknown command: $Command"
        Show-Help
        exit 1
    }
}
