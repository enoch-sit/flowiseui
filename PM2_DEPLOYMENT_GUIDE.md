# PM2 Deployment Guide - FlowiseAI Frontend

## 🚀 Complete PM2 Setup Guide

### Prerequisites
- Node.js 18+ installed
- PM2 installed globally

### Step 1: Install PM2 Globally
```bash
npm install -g pm2
```

### Step 2: Create PM2 Ecosystem File
Create `ecosystem.config.cjs` in your project root:

```javascript
module.exports = {
  apps: [{
    name: 'flowise-frontend',
    script: 'npm',
    args: 'run preview -- --host 0.0.0.0 --port 3002',
    cwd: '/path/to/your/project',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 3002
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 3002
    },
    log_file: './logs/combined.log',
    out_file: './logs/out.log',
    error_file: './logs/error.log',
    log_date_format: 'YYYY-MM-DD HH:mm Z'
  }]
};
```

### Step 3: Deployment Commands

#### Quick Start (One-liner)
```bash
# Install, build, and start with PM2
npm install && npm run build && pm2 start ecosystem.config.cjs --env production
```

#### Step-by-step Deployment
```bash
# 1. Install dependencies
npm install

# 2. Build the application
npm run build

# 3. Create logs directory
mkdir logs

# 4. Start with PM2
pm2 start ecosystem.config.cjs --env production

# 5. Save PM2 configuration (auto-start on reboot)
pm2 save
pm2 startup
```

### Step 4: PM2 Management Commands

#### Application Control
```bash
# Start application
pm2 start flowise-frontend

# Stop application
pm2 stop flowise-frontend

# Restart application
pm2 restart flowise-frontend

# Reload application (zero downtime)
pm2 reload flowise-frontend

# Delete application from PM2
pm2 delete flowise-frontend
```

#### Monitoring
```bash
# View application status
pm2 status

# View logs (real-time)
pm2 logs flowise-frontend

# View logs (last 100 lines)
pm2 logs flowise-frontend --lines 100

# Monitor CPU/Memory usage
pm2 monit

# Web-based monitoring
pm2 web
```

#### Process Management
```bash
# List all processes
pm2 list

# Show detailed info about process
pm2 show flowise-frontend

# View process logs
pm2 logs

# Clear all logs
pm2 flush
```

### Step 5: Environment Configuration

Your `.env` file should contain:
```bash
VITE_FLOWISE_BASE_URL=https://project-1-13.eduhk.hk
VITE_FLOWISE_CHATFLOW_ID=415615d3-ee34-4dac-be19-f8a20910f692
VITE_FLOWISE_API_KEY=your-api-key
VITE_BASE_PATH=/projectui
VITE_PORT=3002
VITE_APP_TITLE=FlowiseAI Chat
VITE_STREAMING_ENABLED=true
```

### Step 6: Nginx Reverse Proxy (Optional)

If using nginx for reverse proxy:

#### Edit Nginx Configuration
```bash
# Edit nginx site configuration (replace $HOSTNAME with your domain/server name)
sudo nano /etc/nginx/sites-available/$HOSTNAME
```

#### Nginx Configuration Example
```nginx
# /etc/nginx/sites-available/project-1-13 (or your hostname)
server {
    listen 80;
    server_name project-1-13;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name project-1-13;
    ssl_certificate /etc/nginx/ssl/dept-wildcard.eduhk/fullchain.crt;
    ssl_certificate_key /etc/nginx/ssl/dept-wildcard.eduhk/dept-wildcard.eduhk.hk.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers HIGH:!aNULL:!MD5;

    client_max_body_size 100M;

    # Default proxy (customize if needed)
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # FlowiseAI Frontend proxy
    location /projectui/ {
        proxy_pass http://localhost:3002/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

#### Nginx Management Commands

```bash
# Test nginx configuration
sudo nginx -t

# Reload nginx (without downtime)
sudo nginx -s reload

# Restart nginx service
sudo systemctl restart nginx

# Check nginx status
sudo systemctl status nginx

# View nginx error logs
sudo tail -f /var/log/nginx/error.log

# View nginx access logs
sudo tail -f /var/log/nginx/access.log
```

### Step 7: Auto-Start on System Boot

```bash
# Generate startup script (run as root/administrator)
pm2 startup

# Save current PM2 processes
pm2 save
```

### Step 8: Health Monitoring

Create a simple health check endpoint in your Vite config or add monitoring:

```bash
# Check if service is running
curl http://localhost:3002/projectui/

# Or use PM2's built-in health check
pm2 ping flowise-frontend
```

## 🔧 Troubleshooting

### Common Issues

#### Port Already in Use
```bash
# Kill process on port 3002
lsof -ti:3002 | xargs kill -9  # Linux/Mac
netstat -ano | findstr :3002   # Windows
```

#### PM2 Not Starting
```bash
# Check PM2 status
pm2 status

# Check logs for errors
pm2 logs flowise-frontend

# Restart PM2 daemon
pm2 kill
pm2 start ecosystem.config.cjs
```

#### Build Errors
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install

# Clean build
rm -rf dist
npm run build
```

#### Vite Preview Host Blocked
If you get "Blocked request. This host is not allowed" error, add to `vite.config.js`:

```javascript
// vite.config.js - Allow all hosts (simple)
preview: {
  allowedHosts: 'all',
  port: parseInt(env.VITE_PORT) || 3002
}

// Or specify specific hosts (more secure)
preview: {
  allowedHosts: [
    'project-1-13.eduhk.hk',
    'localhost',
    '127.0.0.1'
  ],
  port: parseInt(env.VITE_PORT) || 3002
}
```

### Performance Tuning

#### For High Traffic
```javascript
// ecosystem.config.cjs
module.exports = {
  apps: [{
    name: 'flowise-frontend',
    script: 'npm',
    args: 'run preview -- --host 0.0.0.0 --port 3002',
    instances: 'max', // Use all CPU cores
    exec_mode: 'cluster',
    max_memory_restart: '1G',
    // ... other config
  }]
};
```

## 🎯 One-Command Deployment

Create `deploy.sh` (Linux/Mac) or `deploy.bat` (Windows):

### deploy.bat (Windows)
```batch
@echo off
echo 🚀 Deploying FlowiseAI Frontend...

echo 📦 Installing dependencies...
npm install

echo 🔨 Building application...
npm run build

echo 📁 Creating logs directory...
if not exist logs mkdir logs

echo 🎯 Starting with PM2...
pm2 start ecosystem.config.cjs --env production

echo 💾 Saving PM2 configuration...
pm2 save

echo ✅ Deployment complete!
echo 🌐 Access your app at: http://localhost:3002/projectui/
echo 📊 Monitor with: pm2 monit
echo 📋 View logs with: pm2 logs flowise-frontend

pause
```

### deploy.sh (Linux/Mac)
```bash
#!/bin/bash
echo "🚀 Deploying FlowiseAI Frontend..."

echo "📦 Installing dependencies..."
npm install

echo "🔨 Building application..."
npm run build

echo "📁 Creating logs directory..."
mkdir -p logs

echo "🎯 Starting with PM2..."
pm2 start ecosystem.config.cjs --env production

echo "💾 Saving PM2 configuration..."
pm2 save

echo "✅ Deployment complete!"
echo "🌐 Access your app at: http://localhost:3002/projectui/"
echo "📊 Monitor with: pm2 monit"
echo "📋 View logs with: pm2 logs flowise-frontend"
```

## 📋 Quick Reference Commands

```bash
# Deploy (first time)
npm install && npm run build && pm2 start ecosystem.config.cjs --env production && pm2 save

# Update (redeploy)
pm2 stop flowise-frontend && npm run build && pm2 restart flowise-frontend

# Monitor
pm2 monit

# Logs
pm2 logs flowise-frontend --lines 50

# Status
pm2 status

# Stop all
pm2 stop all

# Restart all
pm2 restart all

# Nginx commands
sudo nginx -t && sudo nginx -s reload  # Test config and reload
sudo systemctl status nginx            # Check nginx status
sudo tail -f /var/log/nginx/error.log  # View nginx errors
```

## 🎉 You're All Set!

Your FlowiseAI frontend will be running on `http://localhost:3002/projectui/` with PM2 managing the process automatically!