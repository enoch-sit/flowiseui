# TODO: Fix Nginx 500 Error - Static File Serving

## 🎯 Current Issue

- Nginx returns 500 Internal Server Error when accessing `/projectui/`
- Error logs show: `Permission denied` and `internal redirection cycle`

## ✅ Steps to Fix (In Order)

### Step 0: Build and Deploy the React App (RECOMMENDED APPROACH!)

**Option A: Use Deployment Script (Recommended)**

```bash
# Navigate to project directory
cd /home/proj13/flowiseui

# Make deployment script executable
chmod +x deploy.sh

# Run the deployment script
./deploy.sh
```

**Option B: Manual Build (Original Method)**

```bash
# Navigate to project directory
cd /home/proj13/flowiseui

# Install dependencies (if not already done)
npm install

# Fix permissions for existing dist folder (if build fails)
sudo rm -rf dist/
# OR if you want to keep it:
sudo chown -R proj13:proj13 dist/
sudo chmod -R 755 dist/

# Build the production version
npm run build

# Verify build files exist
ls -la dist/
ls -la dist/assets/
```

### Step 1: Fix File Permissions (Only needed if NOT using deploy.sh script)

```bash
# Check current permissions (if using manual approach)
ls -la /var/www/html/projectui/

# Fix directory permissions for nginx access (deploy.sh does this automatically)
sudo chmod 755 /var/www/html/
sudo chmod 755 /var/www/html/projectui/
sudo chmod -R 755 /var/www/html/projectui/
sudo chown -R www-data:www-data /var/www/html/projectui/

# Verify permissions are correct
ls -la /var/www/html/projectui/
```

### Step 2: Fix Nginx Configuration - Option A (Recommended)

```bash
# Edit nginx configuration
sudo nano /etc/nginx/sites-available/$HOSTNAME

# IMPORTANT: Place this BEFORE the location / { proxy_pass... } block
# The /projectui/ location block should come before the general / location:

location /projectui/ {
    alias /var/www/html/projectui/;
    try_files $uri $uri/index.html /projectui/index.html;
    index index.html;
}

# This should come AFTER the /projectui/ block:
location / {
    proxy_pass http://localhost:3000;  # Proxy to Flowise on port 3000
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

### Step 3: Test and Reload

```bash
# Test nginx configuration syntax
sudo nginx -t

# If test passes, reload nginx
sudo nginx -s reload

# Test the website
curl -I https://project-1-13.eduhk.hk/projectui/
```

### Step 4: Alternative Config (If Step 2 doesn't work)

```nginx
# Try this simpler configuration:
location /projectui {
    alias /home/proj13/flowiseui/dist;
    try_files $uri $uri/ /index.html;
    index index.html;
}
```

### Step 5: Alternative Config with Named Location (If Step 4 doesn't work)

```nginx
# Try with named location to avoid redirection cycle:
location /projectui/ {
    alias /home/proj13/flowiseui/dist/;
    try_files $uri $uri/ @fallback;
}

location @fallback {
    rewrite ^/projectui/(.*)$ /projectui/index.html last;
}
```

## 🔍 Debugging Commands

### Common "JavaScript Required" Error Solutions

**This error typically means:**

1. 🔴 **JavaScript files not found (404)** - Check nginx config and file paths
2. 🔴 **Incorrect MIME type** - JavaScript served as text/plain instead of application/javascript  
3. 🔴 **Permission denied** - nginx can't read the asset files
4. 🔴 **Missing base path** - Assets referenced without `/projectui/` prefix

**Quick diagnostic:**

```bash
# 1. Check if assets are accessible
curl -I https://project-1-13.eduhk.hk/projectui/assets/index-b1b4d680.js

# 2. Expected response should include:
# - HTTP/1.1 200 OK
# - Content-Type: application/javascript

# If you get 404, check nginx config and file permissions
# If you get wrong Content-Type, add MIME type rules
```

### Check Error Logs

```bash
# Monitor error logs in real-time
sudo tail -f /var/log/nginx/error.log

# Check last 20 error lines
sudo tail -20 /var/log/nginx/error.log
```

### Check File Access

```bash
# Test if nginx user can access files
sudo -u www-data ls -la /home/proj13/flowiseui/dist/
sudo -u www-data cat /home/proj13/flowiseui/dist/index.html
```

### Verify Build Files

```bash
# Ensure build files exist and are correct
cd /home/proj13/flowiseui
ls -la dist/
cat dist/index.html | head -10
```

### Debug "JavaScript Required" Error

```bash
# Test direct access to JavaScript files
curl -I https://project-1-13.eduhk.hk/projectui/assets/index-b1b4d680.js
curl -I https://project-1-13.eduhk.hk/projectui/assets/index-6b372cb5.css

# Check MIME types in nginx
sudo nginx -T | grep -A 5 -B 5 "mime.types"

# Test if files are accessible via nginx
sudo -u www-data curl -I http://localhost/projectui/
sudo -u www-data curl -I http://localhost/projectui/assets/index-b1b4d680.js
```

### Common Nginx MIME Type Fix

```bash
# Ensure JavaScript files are served with correct MIME type
# Add this to nginx configuration if missing:
location ~* \.js$ {
    add_header Content-Type application/javascript;
}

location ~* \.css$ {
    add_header Content-Type text/css;
}
```

## 🎯 Expected Outcome

- ✅ No more 500 errors
- ✅ Static files served directly by nginx
- ✅ No need for PM2 or preview server
- ✅ Better performance and reliability

## 📝 Notes

- Current approach: Static file serving (no PM2 needed)
- Nginx serves files from: `/home/proj13/flowiseui/dist/`
- Base path configured as: `/projectui/`
- Backend (Flowise) still on port 3000
- Frontend now served as static files instead of port 3002
