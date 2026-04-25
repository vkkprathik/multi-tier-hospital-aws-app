# Docker Deployment Setup - Hospital App

## 📦 What Was Set Up

Your Multi-Tier Hospital Application is now fully containerized with Docker! Here's what has been configured:

### ✅ Files Created

| File | Purpose |
|------|---------|
| `Dockerfile` | Flask application container definition with gunicorn WSGI server |
| `docker-compose.yml` | Multi-container orchestration (app, database, phpMyAdmin) |
| `.dockerignore` | Exclude unnecessary files from Docker image builds |
| `.env.example` | Environment variables template |
| `DOCKER_DEPLOYMENT.md` | Comprehensive Docker deployment guide |
| `QUICK_START.md` | 2-minute quick start guide |
| `scripts/init.sql` | MySQL database initialization script |
| `scripts/docker-deploy.ps1` | PowerShell deployment helper script |
| `scripts/docker-deploy.sh` | Bash deployment helper script |
| `Makefile` | Build automation commands (Linux/macOS) |
| `.github/workflows/docker-ci.yml` | CI/CD pipeline for automated testing |

### 📋 Updated Files

- **`application/config.py`** - Now supports environment variables for Docker configuration
- **`application/requirements.txt`** - Added PyMySQL driver for MySQL connections
- **`.gitignore`** - Added Docker-specific patterns

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│        Docker Compose Network            │
│  (hospital_network - bridge)             │
└─────────────────────────────────────────┘
         │                    │                    │
    ┌────▼───┐           ┌────▼────┐       ┌─────▼──────┐
    │   App  │           │ Database │       │ phpMyAdmin │
    │ Service│           │ (MySQL)  │       │  (Optional)│
    │        │           │          │       │            │
    │ Flask  │           │ MySQL 8.0│       │ Web UI     │
    │ 5000   │           │ 3306     │       │ 8080       │
    └────┬───┘           └────┬─────┘       └─────┬──────┘
         │                    │                    │
         ├────────────────────┼────────────────────┤
         │                    │                    │
    Volumes              Volumes            Volumes
    - Code               - mysql_data       - (ephemeral)
    - Logs
```

---

## 🎯 Services

### 1. **app** - Flask Application
- **Image**: Custom built from `Dockerfile`
- **Port**: 5000 (configurable via `APP_PORT` in `.env`)
- **Server**: Gunicorn (4 workers)
- **Health Check**: HTTP endpoint check every 30s
- **Volumes**: Code and logs mount for development

### 2. **database** - MySQL
- **Image**: MySQL 8.0
- **Port**: 3306 (configurable via `DB_PORT` in `.env`)
- **Storage**: Persistent volume (`mysql_data`)
- **Health Check**: mysqladmin ping every 10s
- **Default Credentials**: hospitaluser / password123

### 3. **phpmyadmin** - Database Management UI
- **Image**: phpMyAdmin latest
- **Port**: 8080 (configurable via `PHPMYADMIN_PORT` in `.env`)
- **Optional**: Can be disabled in production

---

## 🔐 Environment Configuration

### Create `.env` file from template:
```bash
cp .env.example .env
```

### Key Variables:
```env
# Flask Settings
FLASK_ENV=production
SECRET_KEY=your-random-secret-key

# Database Settings
DB_HOST=database
DB_PORT=3306
DB_NAME=hospital
DB_USER=hospitaluser
DB_PASSWORD=password123

# Application
APP_PORT=5000
PHPMYADMIN_PORT=8080
```

**⚠️ Important**: Change default passwords before deploying to production!

---

## 📚 Usage Examples

### Start Services
```bash
docker-compose up -d
docker-compose ps  # Check status
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f app
docker-compose logs -f database
```

### Access Application
```bash
# Web UI
http://localhost:5000/

# Database management
http://localhost:8080/

# Default Hospital App credentials
Username: kaashvi
Password: kaashvi123
```

### Database Management
```bash
# Connect to MySQL
docker-compose exec database mysql -u hospitaluser -p hospital

# Backup database
docker-compose exec -T database mysqldump -u hospitaluser -ppassword123 hospital > backup.sql

# Restore database
docker-compose exec -T database mysql -u hospitaluser -ppassword123 hospital < backup.sql
```

### Application Shell Access
```bash
docker-compose exec app bash
```

### Stop Services
```bash
# Stop containers
docker-compose down

# Stop and remove volumes (WARNING: deletes data)
docker-compose down -v
```

---

## 🛠️ Available Tools

### Using Docker Compose
```bash
docker-compose up -d        # Start
docker-compose down         # Stop
docker-compose logs -f      # View logs
docker-compose ps          # Status
```

### Using Makefile (Linux/macOS)
```bash
make start                  # Start services
make stop                   # Stop services
make logs-app              # View app logs
make shell                 # App shell
make backup                # Backup database
make health-check          # System health
make help                  # All commands
```

### Using PowerShell Script (Windows)
```powershell
.\scripts\docker-deploy.ps1 -Command start
.\scripts\docker-deploy.ps1 -Command logs -Argument app
.\scripts\docker-deploy.ps1 -Command shell
.\scripts\docker-deploy.ps1 -Command backup
.\scripts\docker-deploy.ps1 -Command health
```

### Using Bash Script (Linux/macOS)
```bash
./scripts/docker-deploy.sh start
./scripts/docker-deploy.sh logs app
./scripts/docker-deploy.sh shell
./scripts/docker-deploy.sh backup
./scripts/docker-deploy.sh health
```

---

## 🔍 Troubleshooting

### Port Already in Use
```bash
# Find process using port
lsof -i :5000              # macOS/Linux
netstat -ano | findstr :5000  # Windows

# Change port in .env
APP_PORT=5001
```

### Database Connection Issues
```bash
# Check database health
docker-compose logs database

# Verify connectivity
docker-compose exec database mysqladmin ping -h localhost -u hospitaluser -ppassword123
```

### Application Won't Start
```bash
# Check logs
docker-compose logs app

# Rebuild image
docker-compose build --no-cache app

# Restart service
docker-compose up -d app
```

---

## 📖 Documentation

- **[DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md)** - Comprehensive Docker guide
- **[QUICK_START.md](QUICK_START.md)** - 2-minute quick start
- **[Docker Official Docs](https://docs.docker.com/)**

---

## 🔄 Development vs Production

### Development Mode
```bash
# Uses docker-compose.override.yml automatically
docker-compose up -d

# Features:
# - Hot code reload
# - Debug logging
# - phpMyAdmin enabled
# - Full port exposure
```

### Production Mode
Update `.env`:
```env
FLASK_ENV=production
SECRET_KEY=<strong-random-key>
DB_PASSWORD=<strong-password>
```

Then:
```bash
# Use production settings
docker-compose up -d
```

---

## 🐳 Docker Image Details

### Flask Application Image
- **Base**: `python:3.11-slim`
- **Size**: ~200MB (optimized)
- **User**: Non-root `appuser` for security
- **Health Check**: HTTP endpoint every 30s
- **Logging**: JSON file driver with rotation

### Database Image
- **Base**: `mysql:8.0` (official)
- **Size**: ~500MB
- **Port**: 3306
- **Health Check**: mysqladmin ping every 10s

---

## 🚀 Deployment Options

### Option 1: Local Development
```bash
docker-compose up -d
# Access: http://localhost:5000
```

### Option 2: AWS ECS
```bash
aws ecs create-service \
  --cluster hospital \
  --service-name hospital-app \
  --task-definition hospital-app
```

### Option 3: Docker Swarm
```bash
docker swarm init
docker stack deploy -c docker-compose.yml hospital
```

### Option 4: Kubernetes
```bash
kompose convert -f docker-compose.yml -o ./k8s/
kubectl apply -f ./k8s/
```

---

## ✅ Pre-Deployment Checklist

- [ ] Docker Desktop installed and running
- [ ] `.env` file created with strong passwords
- [ ] Port 5000 and 3306 are available
- [ ] Sufficient disk space for database volume
- [ ] System has at least 4GB RAM available
- [ ] `.env.example` copied to `.env`
- [ ] Secret key changed in `.env`
- [ ] Database passwords changed in `.env`

---

## 📊 Monitoring

### Check Container Health
```bash
docker-compose ps
docker stats
```

### View Resource Usage
```bash
# Real-time stats
docker stats

# Per-service
docker-compose stats
```

### Application Health
```bash
# Test app endpoint
curl http://localhost:5000/

# Database connectivity
docker-compose exec database mysqladmin ping
```

---

## 🔒 Security Considerations

1. **Change Default Credentials**
   - `SECRET_KEY` in `.env`
   - `DB_PASSWORD` in `.env`
   - `DB_ROOT_PASSWORD` in `.env`

2. **Network Security**
   - Services only connect via `hospital_network`
   - No unnecessary port exposure
   - Firewall rules recommended

3. **Image Security**
   - Use specific image versions (not `latest`)
   - Regular security updates
   - Scan images: `docker scan hospital-app`

4. **Production Safety**
   - Disable phpMyAdmin in production
   - Set `FLASK_ENV=production`
   - Use HTTPS/SSL proxy
   - Regular backups

---

## 📞 Support

- **[DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md)** - Full documentation
- **[QUICK_START.md](QUICK_START.md)** - Getting started
- **Troubleshooting**: Check `docker-compose logs`
- **Docker Help**: https://docs.docker.com/

---

## 🎓 Learning Resources

- [Docker Tutorial](https://www.docker.com/101-tutorial)
- [Docker Compose Guide](https://docs.docker.com/compose/)
- [Flask Deployment](https://flask.palletsprojects.com/deployment/)
- [MySQL Docker Hub](https://hub.docker.com/_/mysql)

---

**Last Updated**: April 26, 2026  
**Docker Version**: 20.10+  
**Docker Compose Version**: 2.0+

---

## 🎉 Next Steps

1. ✅ Review the setup files created
2. ✅ Copy `.env.example` to `.env`
3. ✅ Update security credentials in `.env`
4. ✅ Run `docker-compose up -d`
5. ✅ Access app at http://localhost:5000
6. ✅ Read [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md) for advanced usage

**Your application is ready for Docker deployment!** 🚀
