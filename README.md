# Blue-Green Deployment of a Dockerized Service Using Nginx and GitHub Actions

## Introduction
This project demonstrates a **Blue-Green Deployment** strategy for a containerized web application using **Docker**, **Nginx**, and **GitHub Actions** on **DigitalOcean**. The goal is to achieve **zero downtime** when deploying updates, allowing seamless switching between two environments: 

- **Blue Server (Active Production)**
- **Green Server (Staging & New Release)**

Nginx acts as a **reverse proxy**, directing traffic to the active environment, and GitHub Actions automates deployment using **SSH and Docker**.

---

## Features
- 🚀 **Zero downtime deployment** with Nginx as a reverse proxy
- 🔄 **Automatic deployment** via GitHub Actions
- 🐳 **Dockerized environment** for consistency across servers
- 🔧 **Environment variables** stored securely in GitHub Secrets
- 🔄 **Rollback mechanism** for quick recovery

---

## Prerequisites
### 1️⃣ DigitalOcean Setup
- A **DigitalOcean** account
- Two **Ubuntu-based Droplets** (for Blue & Green environments)
- **Nginx installed** for routing requests
- A registered domain (optional, but recommended)

### 2️⃣ GitHub Setup
- A **GitHub repository** with your project code
- **GitHub Actions** enabled
- Repository **secrets configured** (see below)

### 3️⃣ Tools Installed on Both Droplets
- **Docker** & **Nginx**
- **SSH access enabled**

---

## Project Structure
```bash
├── .github/workflows/deploy.yml   # GitHub Actions CI/CD pipeline
├── Dockerfile                     # Docker build configuration
├── app/                            # Application source code
├── nginx/
│   ├── nginx.conf                  # Reverse proxy configuration
│   ├── sites-available/
│   │   ├── default                 # Nginx config for Blue-Green
├── README.md                      # Documentation (this file)
```

---

## Step 1: Create DigitalOcean Droplets
1. Go to [DigitalOcean](https://www.digitalocean.com/).
2. Click **Create → Droplets**.
3. Choose **Ubuntu 22.04** as the OS.
4. Select a **2GB RAM, 1 vCPU Droplet** (or higher).
5. Create two Droplets:
   - **Blue Environment** (`blue-server`)
   - **Green Environment** (`green-server`)
6. Add **SSH keys** for secure access.

---

## Step 2: Install Docker & Nginx
Run the following commands on both **Blue** and **Green** servers:
```bash
sudo apt update
sudo apt install -y docker.io nginx
sudo systemctl enable docker nginx
sudo systemctl start docker nginx
```

### Verify Installation:
```bash
docker --version   # Should return Docker version
docker ps          # Should return running containers
nginx -v           # Should return Nginx version
```

---

## Step 3: Configure Nginx for Blue-Green Deployment
1. Open the default Nginx configuration file:
```bash
sudo nano /etc/nginx/sites-available/default
```
2. Update the **proxy_pass** directive to use `$ACTIVE_SERVER`:
```nginx
server {
    listen 80;
    location / {
        proxy_pass http://$ACTIVE_SERVER:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```
3. Save and restart Nginx:
```bash
sudo systemctl restart nginx
```

---

## Step 4: Set Up GitHub Secrets for CI/CD
Go to your **GitHub Repository → Settings → Secrets and Variables → Actions** and add the following:
- **`BLUE_HOST`** → `blue-server-ip`
- **`GREEN_HOST`** → `green-server-ip`
- **`DOCKERHUB_USERNAME`** → *Your Docker Hub username*
- **`DOCKERHUB_PASSWORD`** → *Your Docker Hub password*
- **`SSH_PRIVATE_KEY`** → *Your SSH private key*

---

## Step 5: Automate Deployment with GitHub Actions
Create a GitHub Actions workflow in `.github/workflows/deploy.yml`:
```yaml
name: Deploy Application
on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3
      
      - name: Deploy to Green Environment
        run: |
          ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa root@${{ secrets.GREEN_HOST }} << 'EOF'
            docker pull ${{ secrets.DOCKERHUB_USERNAME }}/my-app:latest
            docker stop my-app || true
            docker rm my-app || true
            docker run -d --name my-app -p 3000:3000 ${{ secrets.DOCKERHUB_USERNAME }}/my-app:latest
          EOF

      - name: Switch Traffic to Green
        run: |
          ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa root@${{ secrets.BLUE_HOST }} << 'EOF'
            echo "GREEN_HOST=${{ secrets.GREEN_HOST }}" > /etc/nginx/env.conf
            systemctl restart nginx
          EOF
```

---

## Step 6: Deploying a New Version
1. Push a new commit to the `main` branch:
```bash
git add .
git commit -m "New feature added"
git push origin main
```
2. GitHub Actions automatically deploys to **Green Server**.
3. Nginx updates `$ACTIVE_SERVER` to **Green Server**.
4. Once stable, manually update the **Blue Server** for future releases.

---

## Step 7: Rollback in Case of Failure
If the new deployment has issues, switch back to the **Blue Environment**:
```bash
ssh root@blue-server-ip
sudo systemctl restart nginx
```

https://roadmap.sh/projects/blue-green-deployment
---

## Conclusion
By following this guide, you now have a **fully automated Blue-Green Deployment strategy** with:
✅ **Zero downtime deployments**
✅ **Automated CI/CD with GitHub Actions**
✅ **Easy rollback with Nginx reverse proxy**

.

📌 **Repository:** [GitHub - eniayo/dockerized-service-deployment](https://github.com/eniayo/dockerized-service-deployment)

🚀 **Happy Deploying!**
