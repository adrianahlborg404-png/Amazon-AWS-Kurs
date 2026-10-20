#!/bin/bash
# =============================================================
# user-data.sh - Novatrix AB, AWS v42
# Kors automatiskt (som root) forsta gangen EC2-instansen startar.
# Installerar Apache och hamtar webbsidan fran GitHub-repot.
# Logg: /var/log/cloud-init-output.log
# =============================================================

# >>> ANDRA till ditt eget repo och din branch <<<
GITHUB_USER="adrianahlborg404-png"
REPO="Amazon-AWS-Kurs"
BRANCH="main"

RAW_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO}/${BRANCH}/v42/webb/index.html"

# 1. Uppdatera systemet och installera Apache (httpd)
dnf update -y
dnf install -y httpd

# 2. Hamta webbsidan fran GitHub
curl -fsSL "$RAW_URL" -o /var/www/html/index.html

# 3. Starta Apache nu och vid varje omstart
systemctl enable --now httpd
