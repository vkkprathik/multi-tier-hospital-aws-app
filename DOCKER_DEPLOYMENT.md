# Docker Deployment Guide for Multi-Tier Hospital App

This guide explains how to deploy the Multi-Tier Hospital Application using Docker and Docker Compose.

## Prerequisites

- **Docker**: Install from [docker.com](https://www.docker.com)
- **Docker Compose**: Usually included with Docker Desktop
- **System Requirements**: 
  - Minimum 4GB RAM
  - 2GB free disk space
  - Windows 10+, macOS 11+, or Linux (Ubuntu 20.04+)

## Project Structure

```
multi-tier-hospital-aws-app/
├── Dockerfile                 # Flask app container definition
├── docker-compose.yml         # Service orchestration
├── .dockerignore              # Files to exclude from Docker image
├── .env.example               # Environment variables template
├── application/               # Flask application
│   ├── app.py
│   ├── models.py
│   ├── config.py
│   ├── requirements.txt
│   ├── static/
│   └── templates/
├── scripts/
│   └── init.sql              # Database initialization script
└── terraform/                # AWS infrastructure (optional)
```

## Quick Start

### 1. Setup Environment Variables

```bash
# Navigate to project root
cd multi-tier-hospital-aws-app

# Copy environment template
cp .env.example .env

# Edit .env with your preferences (optional)
```

### 2. Build and Run Containers

```bash
# Build Docker image and start services
docker-compose up -d

# View logs
docker-compose logs -f app

# Or view database logs
docker-compose logs -f database
```

### 3. Verify Deployment

```bash
# Check if all services are running
docker-compose ps

# Test the application
curl http://localhost:5000

# Check application health
curl http://localhost:5000/health
```

### 4. Access the Application

- **Hospital App**: http://localhost:5000
- **phpMyAdmin**: http://localhost:8080 (optional database management UI)

## Docker Services

### 1. Database Service (`database`)
- **Image**: MySQL 8.0
- **Port**: 3306 (internal), exposed on configurable port
- **Volume**: `mysql_data` (persistent storage)
- **Health Check**: Enabled
- **Environment**: Database name, user, and password configurable via `.env`

### 2. Application Service (`app`)
- **Build**: From `Dockerfile`
- **Port**: 5000 (configurable via `APP_PORT` in `.env`)
- **Volumes**: 
  - Application code (hot-reload in development)
  - Application logs
- **Depends On**: Database service (waits for health check)
- **Health Check**: HTTP endpoint check
- **Logging**: JSON file driver with log rotation

### 3. phpMyAdmin Service (Optional)
- **Image**: phpMyAdmin latest
- **Port**: 8080 (configurable via `PHPMYADMIN_PORT` in `.env`)
- **Purpose**: Web UI for database management

## Configuration

### Environment Variables (.env)

```env
# Flask Settings
FLASK_ENV=production
SECRET_KEY=your-secret-key-change-in-production

# Database Settings
DB_HOST=database
DB_PORT=3306
DB_NAME=hospital
DB_USER=hospitaluser
DB_PASSWORD=password123
DB_ROOT_PASSWORD=rootpass123

# Application Settings
APP_PORT=5000
PHPMYADMIN_PORT=8080

# Logging
LOG_LEVEL=INFO
```

**Important Security Notes:**
- Change `SECRET_KEY` in production
- Change `DB_PASSWORD` and `DB_ROOT_PASSWORD`
- Use strong passwords for production environments

## Common Commands

### Start Services
```bash
# Start all services in background
docker-compose up -d

# Start with specific services
docker-compose up -d app database

# Rebuild images before starting
docker-compose up -d --build
```

### Stop Services
```bash
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: loses data)
docker-compose down -v

# Stop specific service
docker-compose stop app
```

### View Logs
```bash
# View all logs
docker-compose logs

# Follow logs in real-time
docker-compose logs -f

# View specific service logs
docker-compose logs -f app
docker-compose logs -f database

# Last 50 lines
docker-compose logs --tail=50
```

### Database Management
```bash
# Connect to MySQL container
docker-compose exec database mysql -u hospitaluser -p hospital

# Run SQL file
docker-compose exec database mysql -u hospitaluser -p hospital < scripts/init.sql

# Backup database
docker-compose exec database mysqldump -u hospitaluser -p hospital > backup.sql

# Restore database
docker-compose exec database mysql -u hospitaluser -p hospital < backup.sql
```

### Application Management
```bash
# Execute commands in app container
docker-compose exec app bash

# Run Python scripts
docker-compose exec app python -c "import app"

# View application files
docker-compose exec app ls -la /app
```

### Debugging
```bash
# Check service status
docker-compose ps

# View service health
docker-compose exec database mysqladmin -u hospitaluser -p ping

# Test app connectivity to database
docker-compose exec app python -c "from config import Config; print(Config.SQLALCHEMY_DATABASE_URI)"
```

## Development vs Production

### Development Mode
```bash
# Use override file for development
docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d

# Benefits: Hot-reload, debug logging, phpMyAdmin enabled
```

### Production Mode
```bash
# Set environment
export FLASK_ENV=production

# Use .env with production values
# Start without override file
docker-compose up -d

# Best practices:
# - Use strong SECRET_KEY
# - Change all default passwords
# - Disable phpMyAdmin
# - Enable HTTPS/SSL
# - Configure logging properly
```

## Troubleshooting

### Issue: Port Already in Use
```bash
# Find service using port (Windows PowerShell)
netstat -ano | findstr :5000

# Kill process
taskkill /PID <PID> /F

# Or change port in .env
APP_PORT=5001
```

### Issue: Database Connection Failed
```bash
# Check if database is ready
docker-compose logs database

# Verify database health
docker-compose exec database mysqladmin ping -h localhost -u hospitaluser -p

# Restart database
docker-compose restart database
```

### Issue: Application Not Starting
```bash
# View application logs
docker-compose logs -f app

# Check if port is available
docker-compose port app 5000

# Rebuild image
docker-compose build --no-cache app
docker-compose up -d app
```

### Issue: Out of Memory
```bash
# Check resource usage
docker stats

# Reduce worker count in Dockerfile
# Change: CMD ["gunicorn", "--workers", "4", ...]
# To: CMD ["gunicorn", "--workers", "2", ...]
```

## Data Persistence

### Volumes

- **mysql_data**: Stores MySQL database files
  - Location on host: Docker managed volume
  - Survives container restart: ✓
  - Survives `docker-compose down`: ✓
  - Removed by `docker-compose down -v`: ✓

- **app_logs**: Stores application logs
  - Location on host: Docker managed volume
  - Path inside: `/app/logs`

### Backup and Restore

```bash
# Backup MySQL data
docker-compose exec database mysqldump -u hospitaluser -p hospital > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore MySQL data
docker-compose exec -T database mysql -u hospitaluser -p hospital < backup_20240101_120000.sql
```

## Security Best Practices

1. **Change Default Credentials**
   - Update all passwords in `.env`
   - Use strong, unique passwords (20+ chars)
   - Never commit `.env` to version control

2. **Network Security**
   - Use `hospital_network` bridge network (isolated)
   - Restrict exposed ports in firewall
   - Use VPN for remote access

3. **Image Security**
   - Use specific image versions (not `latest`)
   - Regularly update base images
   - Scan images for vulnerabilities: `docker scan`

4. **Application Security**
   - Set `SECRET_KEY` to random value
   - Enable `SESSION_COOKIE_SECURE = True` (requires HTTPS)
   - Configure HTTPS/SSL in production
   - Use environment variables for sensitive data

5. **Database Security**
   - Use non-root database user
   - Limit database user privileges
   - Regular backups
   - Encrypt backups in transit

## Performance Optimization

### Resource Limits
```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

### Scaling
```bash
# Scale application service (multiple instances)
docker-compose up -d --scale app=3

# Note: Requires load balancer configuration
```

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Docker Build & Push
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build Docker image
        run: docker build -t hospital-app:${{ github.sha }} .
      - name: Test with Docker Compose
        run: docker-compose up -d && sleep 10 && curl http://localhost:5000
```

## Deployment to Production

### Option 1: Docker Swarm
```bash
docker swarm init
docker stack deploy -c docker-compose.yml hospital
```

### Option 2: Kubernetes
```bash
# Convert docker-compose to Kubernetes manifests
kompose convert -f docker-compose.yml -o ./k8s/

# Deploy to Kubernetes
kubectl apply -f ./k8s/
```

### Option 3: Cloud Platforms

**AWS ECS**: Use Fargate for serverless containers
**Azure Container Instances**: Quick deployment
**Google Cloud Run**: Serverless container platform
**DigitalOcean App Platform**: Simple deployment

## Monitoring & Logging

### View Logs
```bash
# Real-time logs
docker-compose logs -f

# Specific service
docker-compose logs -f app

# Last 100 lines
docker-compose logs --tail=100
```

### Health Checks
```bash
# Check service health
docker-compose exec app curl -f http://localhost:5000/ || exit 1
docker-compose exec database mysqladmin ping
```

## Cleanup

```bash
# Stop and remove containers
docker-compose down

# Remove containers, volumes, and networks
docker-compose down -v

# Remove unused images
docker image prune

# Remove all unused resources
docker system prune -a
```

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Flask Docker Best Practices](https://flask.palletsprojects.com/deployment/)
- [MySQL Docker Image](https://hub.docker.com/_/mysql)

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review Docker logs: `docker-compose logs`
3. Check Docker official documentation
4. Verify environment variables: `docker-compose config`

---

**Last Updated**: April 26, 2026
**Version**: 1.0
