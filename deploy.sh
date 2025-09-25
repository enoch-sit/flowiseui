#!/bin/bash

# FlowiseUI Deployment Script
# This script builds the React app and deploys it to nginx serving directory
# avoiding permission issues in the development folder

set -e  # Exit on any error

# Configuration
DEV_DIR="/home/proj13/flowiseui"
NGINX_DIR="/var/www/html/projectui"
BACKUP_DIR="/var/www/backup/projectui-$(date +%Y%m%d-%H%M%S)"

echo "🚀 Starting FlowiseUI deployment..."

# Navigate to development directory
cd "$DEV_DIR"

# Clean any existing build artifacts in dev folder
echo "🧹 Cleaning existing build..."
rm -rf dist/

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Build the application
echo "🔨 Building React application..."
npm run build

# Check if build was successful
if [ ! -d "dist" ]; then
    echo "❌ Build failed - dist directory not found"
    exit 1
fi

# Create nginx directory if it doesn't exist
echo "📁 Preparing nginx directory..."
sudo mkdir -p "$NGINX_DIR"

# Backup existing files if they exist
if [ -d "$NGINX_DIR" ] && [ "$(ls -A $NGINX_DIR)" ]; then
    echo "💾 Backing up existing files to $BACKUP_DIR..."
    sudo mkdir -p "$BACKUP_DIR"
    sudo cp -r "$NGINX_DIR"/* "$BACKUP_DIR/"
fi

# Copy built files to nginx directory
echo "📋 Copying files to nginx directory..."
sudo cp -r dist/* "$NGINX_DIR/"

# Set proper ownership and permissions for nginx
echo "🔐 Setting proper permissions..."
sudo chown -R www-data:www-data "$NGINX_DIR"
sudo chmod -R 755 "$NGINX_DIR"

# Clean up dev build folder to avoid future permission issues
echo "🧹 Cleaning development build folder..."
rm -rf dist/

# Test nginx configuration
echo "🔍 Testing nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"
    echo "🔄 Reloading nginx..."
    sudo nginx -s reload
    echo "✅ Nginx reloaded successfully"
else
    echo "❌ Nginx configuration test failed"
    exit 1
fi

# Verify deployment
echo "🔍 Verifying deployment..."
if [ -f "$NGINX_DIR/index.html" ]; then
    echo "✅ Deployment successful!"
    echo "📁 Files deployed to: $NGINX_DIR"
    echo "🌐 Access your app at: https://project-1-13.eduhk.hk/projectui/"
    
    echo ""
    echo "📊 Deployed files:"
    sudo ls -la "$NGINX_DIR"
else
    echo "❌ Deployment failed - index.html not found"
    exit 1
fi

echo ""
echo "🎉 Deployment completed successfully!"