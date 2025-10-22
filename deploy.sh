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

# -------------------------------
# Step 5: Clone or update repository
# -------------------------------

log "📦 Cloning or updating the repository..."

# Build authenticated repo URL
AUTH_URL=${REPO_URL/https:\/\//https://${PAT}@}

# Extract repo name from URL
REPO_NAME=$(basename -s .git "$REPO_URL")

# Clone or update the repo
if [ -d "$REPO_NAME" ]; then
    log "🔄 Repository already exists. Pulling latest changes..."
    cd "$REPO_NAME"
    git pull origin "$BRANCH" || { log "❌ Failed to pull latest changes."; exit 1; }
else
    log "📥 Cloning repository from $REPO_URL..."
    git clone --branch "$BRANCH" "$AUTH_URL" || { log "❌ Failed to clone repository."; exit 1; }
    cd "$REPO_NAME"
fi

# Verify Dockerfile or docker-compose.yml exists
if [ -f Dockerfile ] || [ -f docker-compose.yml ]; then
    log "✅ Docker configuration file found."
else
    log "❌ No Dockerfile or docker-compose.yml found. Exiting..."
    exit 1
fi
# -------------------------------
# Step 6: Test SSH connectivity
# -------------------------------

log "🔐 Testing SSH connection to remote server..."

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$SERVER_IP" "echo '✅ SSH connection successful!'" || {
    log "❌ SSH connection failed. Please check your key, username, or IP."
    exit 1
}

log "✅ SSH connectivity confirmed."

# -------------------------------
# Step 7: Prepare remote environment
# -------------------------------

log "⚙️ Setting up remote environment..."

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$SERVER_IP" << 'EOF'
set -e

echo "[Remote] 🧩 Checking and installing required tools..."

# Update packages
sudo apt-get update -y

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "[Remote] 🐳 Installing Docker..."
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    echo "[Remote] ✅ Docker installed successfully!"
else
    echo "[Remote] ✅ Docker already installed."
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    echo "[Remote] 🧩 Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "[Remote] ✅ Docker Compose installed successfully!"
else
    echo "[Remote] ✅ Docker Compose already installed."
fi

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

echo "[Remote] 🚀 Remote environment setup complete!"
EOF

log "✅ Remote environment ready."

# -------------------------------
# Step 8: Deploy Docker container remotely
# -------------------------------

log "🚀 Starting remote deployment..."

# Copy project files to the remote server
log "📦 Uploading project files to server..."
rsync -avz -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=no" ./ "$SSH_USER@$SERVER_IP":~/app

# SSH into server and deploy container
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$SERVER_IP" << EOF
set -e

cd ~/app

echo "[Remote] 🐳 Building Docker image..."
sudo docker build -t hng13-app .

echo "[Remote] 🧹 Removing old container (if exists)..."
sudo docker stop hng13-container || true
sudo docker rm hng13-container || true

echo "[Remote] 🚀 Running new container..."
sudo docker run -d -p $APP_PORT:$APP_PORT --name hng13-container hng13-app

echo "[Remote] ✅ Deployment successful! Container running on port $APP_PORT"
EOF

log "✅ Remote Docker container deployed successfully!"

# -------------------------------
# STEP 7-10 UPDATES START
# -------------------------------

# Step 7 (Nginx reverse proxy)
log "🌐 Configuring Nginx as reverse proxy..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$SERVER_IP" << EOF
set -e
sudo apt-get install -y nginx

# Remove old config if exists
sudo rm -f /etc/nginx/sites-enabled/hng13-app

# Create new Nginx config
echo "server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://localhost:$APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}" | sudo tee /etc/nginx/sites-available/hng13-app

sudo ln -sf /etc/nginx/sites-available/hng13-app /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
EOF

log "✅ Nginx configured successfully, forwarding port 80 to container port $APP_PORT"

# Step 8 (Validate deployment)
log "🔍 Validating deployment..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$SERVER_IP" << EOF
set -e
sudo docker ps | grep hng13-container
curl -f http://localhost:$APP_PORT || { echo "❌ App endpoint check failed"; exit 1; }
curl -f http://localhost || { echo "❌ Nginx proxy check failed"; exit 1; }
EOF

log "✅ Deployment validated successfully! App should be accessible at http://$SERVER_IP/"

# Step 10: Idempotency / Optional cleanup
if [ "$1" = "--cleanup" ]; then
    log "🧹 Cleanup mode: removing container, Docker image, and Nginx config..."
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$SERVER_IP" << EOF
    set -e
    sudo docker stop hng13-container || true
    sudo docker rm hng13-container || true
    sudo docker rmi hng13-app || true
    sudo rm -f /etc/nginx/sites-enabled/hng13-app
    sudo systemctl reload nginx || true
EOF
    log "✅ Cleanup complete."
    exit 0
fi

# -------------------------------
# STEP 7-10 UPDATES END
# -------------------------------
