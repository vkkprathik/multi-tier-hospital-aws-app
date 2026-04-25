# Quick Start Guide - Docker Deployment

## 🚀 Get Started in 2 Minutes

### On Windows (PowerShell)

```powershell
# 1. Navigate to project directory
cd multi-tier-hospital-aws-app

# 2. Copy environment file
Copy-Item .env.example .env

# 3. Start Docker services
docker-compose up -d

# 4. Access the application
# Open browser: http://localhost:5000

# 5. Stop services when done
docker-compose down
```

### On macOS / Linux (Bash)

```bash
# 1. Navigate to project directory
cd multi-tier-hospital-aws-app

# 2. Copy environment file
cp .env.example .env

# 3. Start Docker services
docker-compose up -d

# 4. Access the application
# Open browser: http://localhost:5000

# 5. Stop services when done
docker-compose down
```

---

## 📋 Prerequisites

- ✅ **Docker Desktop** installed and running
  - [Download for Windows](https://www.docker.com/products/docker-desktop)
  - [Download for macOS](https://www.docker.com/products/docker-desktop)
  - [Install on Linux](https://docs.docker.com/desktop/install/linux-installation/)

---

## 🎯 Default Credentials

| Service | URL | Username | Password |
|---------|-----|----------|----------|
| Hospital App | http://localhost:5000 | kaashvi | kaashvi123 |
| phpMyAdmin | http://localhost:8080 | hospitaluser | password123 |
| MySQL | localhost:3306 | hospitaluser | password123 |

---

## 📚 Available Commands

### Using Docker Compose directly

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# View app logs only
docker-compose logs -f app

# Access app shell
docker-compose exec app bash

# Access database
docker-compose exec database mysql -u hospitaluser -p hospital
```

### Using Make (Linux/macOS)

```bash
# View all commands
make help

# Start services
make start

# View logs
make logs-app

# Check health
make health-check

# Backup database
make backup
```

### Using PowerShell Script (Windows)

```powershell
# Start services
.\scripts\docker-deploy.ps1 -Command start

# View logs
.\scripts\docker-deploy.ps1 -Command logs -Argument app

# Check health
.\scripts\docker-deploy.ps1 -Command health

# Backup database
.\scripts\docker-deploy.ps1 -Command backup
```

### Using Bash Script (Linux/macOS)

```bash
# Start services
./scripts/docker-deploy.sh start

# View logs
./scripts/docker-deploy.sh logs app

# Check health
./scripts/docker-deploy.sh health

# Backup database
./scripts/docker-deploy.sh backup
```

---

## 🔍 Verify Deployment

After starting services:

```bash
# Check all services are running
docker-compose ps

# Test application
curl http://localhost:5000

# Check database
docker-compose exec database mysqladmin ping -u hospitaluser -p

# View application logs
docker-compose logs app

# View database logs
docker-compose logs database
```

---

## 📁 Project Structure

```
multi-tier-hospital-aws-app/
├── Dockerfile                    # Flask container definition
├── docker-compose.yml            # Service orchestration
├── docker-compose.override.yml   # Development overrides
├── .env.example                  # Environment template
├── .dockerignore                 # Docker build exclusions
├── Makefile                      # Build automation (Linux/macOS)
├── application/                  # Flask application
│   ├── app.py                   # Main application
│   ├── config.py                # Configuration
│   ├── models.py                # Database models
│   ├── requirements.txt          # Python dependencies
│   ├── static/                  # Static files (CSS, JS)
│   └── templates/               # HTML templates
├── scripts/
│   ├── docker-deploy.sh         # Deployment script (Bash)
│   ├── docker-deploy.ps1        # Deployment script (PowerShell)
│   └── init.sql                 # Database initialization
├── terraform/                    # AWS infrastructure (optional)
├── DOCKER_DEPLOYMENT.md         # Detailed Docker guide
└── QUICK_START.md               # This file
```

---

## 🐛 Troubleshooting

### Port Already in Use

```bash
# Windows (PowerShell)
netstat -ano | findstr :5000

# macOS/Linux
lsof -i :5000

# Change port in .env
APP_PORT=5001
docker-compose up -d
```

### Database Connection Error

```bash
# Check database is ready
docker-compose logs database

# Restart database
docker-compose restart database

# Wait for it to be healthy
docker-compose exec database mysqladmin ping -u hospitaluser -p
```

### Application Fails to Start

```bash
# View detailed logs
docker-compose logs -f app

# Rebuild image
docker-compose build --no-cache app

# Restart
docker-compose up -d app
```

### Out of Memory

```bash
# Check resource usage
docker stats

# Stop all services
docker-compose down

# Free up resources on your system
# Restart Docker Desktop if on Windows/macOS
```

---

## 💾 Backup & Restore

### Backup Database

```bash
# Using Docker Compose
docker-compose exec -T database mysqldump -u hospitaluser -ppassword123 hospital > backup.sql

# Using Makefile
make backup

# Using script (PowerShell)
.\scripts\docker-deploy.ps1 -Command backup
```

### Restore Database

```bash
# Using Docker Compose
docker-compose exec -T database mysql -u hospitaluser -ppassword123 hospital < backup.sql

# Using script (PowerShell)
.\scripts\docker-deploy.ps1 -Command restore -Argument backups\backup.sql
```

---

## 🔐 Security Checklist

- [ ] Change `SECRET_KEY` in `.env`
- [ ] Change database password in `.env`
- [ ] Change MySQL root password in `.env`
- [ ] Never commit `.env` to version control
- [ ] Use strong, unique passwords (20+ characters)
- [ ] Configure HTTPS/SSL in production
- [ ] Disable phpMyAdmin in production
- [ ] Regular database backups
- [ ] Monitor container logs for errors

---

## 📖 Next Steps

1. **Read** [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md) for detailed documentation
2. **Customize** `.env` file with your settings
3. **Deploy** to production using deployment guide
4. **Monitor** application logs and health
5. **Backup** database regularly

---

## 🆘 Need Help?

1. Check [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md) for detailed troubleshooting
2. Review Docker logs: `docker-compose logs`
3. Check [Docker documentation](https://docs.docker.com/)
4. Review application logs: `docker-compose logs app`

---

## 📞 Support Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [MySQL Documentation](https://dev.mysql.com/doc/)

---

**Last Updated**: April 26, 2026  
**Version**: 1.0
