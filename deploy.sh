#!/bin/bash 

# HNG Stage 1 - DevOps Automated Deployment Script

set -e  # Exit immediately on error
LOG_FILE="deploy_$(date +%Y%m%d).log"

# This Function is to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# This Traps unexpected errors
trap 'log "❌ An unexpected error occurred. Exiting."; exit 1' ERR

# Start message
log "🚀 Starting deployment process..."

# Step 4: This Collects user inputs 
read -p "Enter Git Repository URL: " REPO_URL
read -p "Enter Personal Access Token (PAT): " PAT
read -p "Enter Branch name (default: main): " BRANCH
BRANCH=${BRANCH:-main}

read -p "Enter remote SSH username: " SSH_USER
read -p "Enter remote server IP: " SERVER_IP
read -p "Enter SSH key path (e.g. ~/.ssh/hng-stage1-key.pem): " SSH_KEY
read -p "Enter application port (internal container port): " APP_PORT

# Simple validation
if [[ -z "$REPO_URL" || -z "$PAT" || -z "$SSH_USER" || -z "$SERVER_IP" || -z "$SSH_KEY" || -z "$APP_PORT" ]]; then
    log "❌ Missing required input. Please fill all details."
    exit 1
fi

log "✅ Inputs received successfully."
