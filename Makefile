# Makefile for Hospital App Docker Deployment
# Simplifies common Docker commands for Unix-like systems

.PHONY: help build start stop restart logs status shell clean backup restore health-check test

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo '$(BLUE)Hospital App Docker Deployment$(NC)'
	@echo ''
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ''
	@echo 'Examples:'
	@echo '  make start          # Start all services'
	@echo '  make logs-app       # View app logs'
	@echo '  make shell          # Access app container'
	@echo ''

check: ## Check Docker and Docker Compose installation
	@docker --version
	@docker-compose --version
	@echo '$(GREEN)✓ Docker is installed$(NC)'

setup: ## Setup environment variables
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo '$(GREEN)✓ .env file created$(NC)'; \
		echo '$(YELLOW)⚠ Please update .env with your configuration$(NC)'; \
	else \
		echo '$(GREEN)✓ .env file already exists$(NC)'; \
	fi

build: ## Build Docker images
	@echo '$(BLUE)Building Docker images...$(NC)'
	@docker-compose build --no-cache
	@echo '$(GREEN)✓ Docker images built successfully$(NC)'

start: setup check ## Start Docker services
	@echo '$(BLUE)Starting Docker services...$(NC)'
	@docker-compose up -d
	@echo '$(GREEN)✓ Docker services started$(NC)'
	@echo '$(BLUE)Waiting for services to be ready...$(NC)'
	@sleep 5
	@docker-compose ps
	@echo ''
	@echo '$(GREEN)Application URLs:$(NC)'
	@echo '  App: http://localhost:5000'
	@echo '  phpMyAdmin: http://localhost:8080'

stop: ## Stop Docker services
	@echo '$(BLUE)Stopping Docker services...$(NC)'
	@docker-compose down
	@echo '$(GREEN)✓ Docker services stopped$(NC)'

restart: stop start ## Restart Docker services

logs: ## View all Docker logs (use: make logs-app or make logs-database)
	@docker-compose logs -f

logs-app: ## View app logs
	@docker-compose logs -f app

logs-database: ## View database logs
	@docker-compose logs -f database

logs-phpmyadmin: ## View phpMyAdmin logs
	@docker-compose logs -f phpmyadmin

status: ## Show services status
	@echo '$(BLUE)Docker Services Status:$(NC)'
	@docker-compose ps
	@echo ''
	@echo '$(BLUE)Service Details:$(NC)'
	@echo -n 'App health: '
	@curl -s http://localhost:5000/ > /dev/null && echo '$(GREEN)✓ Running$(NC)' || echo '$(YELLOW)⚠ Not responding$(NC)'
	@echo -n 'Database health: '
	@docker-compose exec -T database mysqladmin ping -h localhost -u hospitaluser -ppassword123 > /dev/null 2>&1 && echo '$(GREEN)✓ Running$(NC)' || echo '$(YELLOW)⚠ Not responding$(NC)'

shell: ## Open bash shell in app container
	@docker-compose exec app bash

shell-db: ## Open MySQL shell in database container
	@docker-compose exec database mysql -u hospitaluser -ppassword123 -h localhost hospital

clean: ## Remove all containers and volumes (WARNING: destructive)
	@echo '$(RED)WARNING: This will remove all containers and volumes!$(NC)'
	@echo -n 'Are you sure? (y/n): '
	@read answer; \
	if [ "$$answer" = "y" ]; then \
		docker-compose down -v; \
		echo '$(GREEN)✓ Cleanup completed$(NC)'; \
	else \
		echo '$(YELLOW)✓ Cleanup cancelled$(NC)'; \
	fi

backup: ## Backup database
	@echo '$(BLUE)Backing up database...$(NC)'
	@mkdir -p backups
	@docker-compose exec -T database mysqldump -u hospitaluser -ppassword123 hospital > backups/hospital_backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo '$(GREEN)✓ Database backed up$(NC)'

restore: ## Restore database (use: make restore FILE=backups/backup.sql)
	@if [ -z "$(FILE)" ]; then \
		echo '$(RED)Error: FILE not specified$(NC)'; \
		echo 'Usage: make restore FILE=backups/backup.sql'; \
		exit 1; \
	fi
	@if [ ! -f "$(FILE)" ]; then \
		echo '$(RED)Error: File not found: $(FILE)$(NC)'; \
		exit 1; \
	fi
	@echo '$(BLUE)Restoring database from $(FILE)...$(NC)'
	@docker-compose exec -T database mysql -u hospitaluser -ppassword123 hospital < $(FILE)
	@echo '$(GREEN)✓ Database restored$(NC)'

health-check: ## Perform system health checks
	@echo '$(BLUE)Performing health checks...$(NC)'
	@echo -n 'Docker daemon: '
	@docker ps > /dev/null 2>&1 && echo '$(GREEN)✓ Running$(NC)' || echo '$(RED)✗ Not running$(NC)'
	@echo -n 'Docker Compose: '
	@docker-compose ps > /dev/null 2>&1 && echo '$(GREEN)✓ Working$(NC)' || echo '$(RED)✗ Failed$(NC)'
	@echo -n 'Application: '
	@curl -s http://localhost:5000/ > /dev/null && echo '$(GREEN)✓ Responding$(NC)' || echo '$(YELLOW)⚠ Not responding$(NC)'
	@echo -n 'Database: '
	@docker-compose exec -T database mysqladmin ping -h localhost -u hospitaluser -ppassword123 > /dev/null 2>&1 && echo '$(GREEN)✓ Responding$(NC)' || echo '$(YELLOW)⚠ Not responding$(NC)'

test: start ## Build, start services, and run basic tests
	@echo '$(BLUE)Running tests...$(NC)'
	@echo -n 'Testing application response: '
	@curl -s http://localhost:5000/ | grep -q 'html' && echo '$(GREEN)✓ OK$(NC)' || echo '$(RED)✗ Failed$(NC)'
	@echo -n 'Testing database connection: '
	@docker-compose exec -T database mysqladmin ping -h localhost -u hospitaluser -ppassword123 > /dev/null 2>&1 && echo '$(GREEN)✓ OK$(NC)' || echo '$(RED)✗ Failed$(NC)'

pull: ## Pull latest base images
	@echo '$(BLUE)Pulling latest base images...$(NC)'
	@docker pull python:3.11-slim
	@docker pull mysql:8.0
	@docker pull phpmyadmin:latest
	@echo '$(GREEN)✓ Images pulled$(NC)'

push: ## Push Docker image to registry (configure registry in docker-compose.yml)
	@echo '$(BLUE)Pushing Docker images...$(NC)'
	@docker-compose push
	@echo '$(GREEN)✓ Images pushed$(NC)'

stats: ## Show Docker resource usage
	@docker stats

prune: ## Remove unused Docker images and containers
	@echo '$(RED)Removing unused Docker resources...$(NC)'
	@docker system prune -f
	@echo '$(GREEN)✓ Prune completed$(NC)'

lint: ## Check docker-compose.yml syntax
	@echo '$(BLUE)Checking docker-compose.yml syntax...$(NC)'
	@docker-compose config > /dev/null && echo '$(GREEN)✓ Configuration is valid$(NC)' || echo '$(RED)✗ Configuration has errors$(NC)'

version: ## Show versions
	@echo '$(BLUE)Version Information:$(NC)'
	@docker --version
	@docker-compose --version
	@echo 'Make: '$$(make --version | head -n1)

.PHONY: help check setup build start stop restart logs logs-app logs-database logs-phpmyadmin status shell shell-db clean backup restore health-check test pull push stats prune lint version
