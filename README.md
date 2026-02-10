# 🚀 Auto Server Setup 
### Automated Ubuntu 22.04 Provisioning for Hetzner

Setting up a fresh VPS shouldn't be a manual chore. This project automates the entire process—from basic hardening to Docker orchestration—getting you from a blank slate to a production-ready environment in minutes.

---

##  Architecture
I've built this stack to be secure, scalable, and easy to monitor:

* **Containerization:** Uses **Docker + Docker Compose** to manage a Flask App and Node Exporter (for those sweet metrics).
* **Routing:** **Nginx** acts as the front door, handling reverse proxying and SSL termination.
* **Security (Hardening):** * **UFW:** Pre-configured firewall rules.
    * **Fail2ban:** Automatically bans suspicious IPs.
    * **SSH Hardening:** Disables insecure defaults.
* **SSL:** Fully automated certificate management via **Let's Encrypt (Certbot)**.

---

## II Quick Start

### 📋 Prerequisites
Before running the script, ensure you have:
* A clean **Ubuntu 22.04** instance.
* A **DNS A record** already pointing to your server's IP.

### III Installation

** 1. Clone the repo and configure environment**
First, grab the source code and set up your `.env` file. This is where you'll define your domain and security credentials.

```bash
git clone [https://github.com/moezha/hetzner-server-bootstrap.git](https://github.com/moezha/hetzner-server-bootstrap.git)
cd hetzner-server-bootstrap
```

** 2 Set up your environment variables **
```bash
cp .env.example .env
nano .env  # need to be edited (DOMAIN, EMAIL, and DEPLOY_PASS_HASH)
```

Note: Generate password hash with openssl passwd -6

** 3 Run Automation ** 
```bash
chmod +x setup.sh
sudo ./setup.sh
```

** 4 Check ** 
Health Check: https://yourdomain.com/health
Metrics: https://yourdomain.com/metrics
