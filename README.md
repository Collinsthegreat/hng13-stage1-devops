# HNG Stage 1 DevOps Project – Automated Deployment Script

## Project Overview

This project is a **robust, automated deployment solution** for a Dockerized application as part of the HNG Stage 1 DevOps tasks. The deployment script, `deploy.sh`, automates cloning a GitHub repository, building and running Docker containers, configuring Nginx as a reverse proxy, and validating the deployment. It also includes logging, input validation, and an optional cleanup mode to ensure **idempotent and reliable deployments**.

This script simulates real-world DevOps workflows, demonstrating automation, error handling, and best practices in continuous deployment.

---

## Table of Contents

- [Features](#features)  
- [Prerequisites](#prerequisites)  
- [Installation / Setup](#installation--setup)  
- [Usage](#usage)  
- [Validation / Testing](#validation--testing)  
- [Troubleshooting](#troubleshooting--common-issues)  
- [Contributing](#contributing-guidelines)  
- [License](#license)  
- [Contact](#contact--author)  

---

## Features

The `deploy.sh` script includes:

- ✅ **Automated cloning and updating** of a GitHub repository using a **Personal Access Token (PAT)**.
- ✅ **Branch selection** (defaults to `main`).
- ✅ **Docker container setup and deployment**.
- ✅ **Nginx reverse proxy configuration** forwarding HTTP traffic to the container’s internal port.
- ✅ **Input validation** to ensure all required parameters are provided.
- ✅ **Error handling and logging** with timestamps.
- ✅ **Idempotent deployments** – safe to re-run without breaking existing setup.
- ✅ **Optional `--cleanup` mode** to remove deployed resources gracefully.
- ✅ Compatible with **Linux remote servers** over SSH.

---

## Prerequisites

Before running the deployment script, ensure you have:

**Local Machine:**

- Bash shell
- SSH client
- Git installed
- GitHub PAT for authentication

**Remote Server:**

- Ubuntu 20.04+ (tested on 24.04)
- Python 3.x
- Docker installed (script can install if missing)
- Docker Compose installed (script can install if missing)
- Nginx installed (script can install if missing)
- SSH access using a private key
- Sufficient privileges to run Docker and manage services

---

## Installation / Setup

1. Clone your HNG DevOps repository locally:

```bash
git clone https://github.com/Collinsthegreat/hng13-stage1-devops.git
cd hng13-stage1-devops

Ensure the deployment script is executable:

chmod +x deploy.sh


Verify that your Dockerfile and app.py exist in the repository root.

Usage

Run the deployment script interactively:

./deploy.sh


You will be prompted to provide:

GitHub repository URL

Personal Access Token (PAT)

Branch name (optional; defaults to main)

Remote SSH username and server IP

SSH private key path

Internal container port

Optional cleanup mode:

./deploy.sh --cleanup


This stops and removes the Docker container, deletes the Docker image, and removes Nginx configuration for a fresh redeployment.

Validation / Testing

After deployment, you can verify your setup:

Check running Docker containers:

ssh -i ~/.ssh/your-key.pem ubuntu@<REMOTE_SERVER_IP>
sudo docker ps


Test the application endpoint:

curl http://<REMOTE_SERVER_IP>:<APP_PORT>


Test Nginx reverse proxy:

curl http://<REMOTE_SERVER_IP>/


Logs and deployment status are available in deploy_YYYYMMDD.log on the local machine.

Troubleshooting / Common Issues

SSH connectivity failure: Ensure correct username, IP, and private key permissions (chmod 600 key.pem).

Docker build fails: Check the Dockerfile and dependencies in requirements.txt.

Nginx configuration errors: Ensure the $APP_PORT is valid and Nginx syntax is correct (sudo nginx -t).

Script exits unexpectedly: Review the timestamped log file deploy_YYYYMMDD.log.

Contributing Guidelines

Contributions are welcome! Please:

Fork the repository

Create a feature branch (git checkout -b feature/my-feature)

Test changes locally

Submit a pull request with a clear description

License

This project is licensed under the MIT License – see LICENSE
 for details.

Contact / Author: Collinsthegreat

GitHub: https://github.com/Collinsthegreat
