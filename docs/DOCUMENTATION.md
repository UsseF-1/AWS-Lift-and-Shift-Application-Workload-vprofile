# Documentation — Lift & Shift vProfile to AWS

This document is a clear, end-to-end guide to deploy the vProfile workload on AWS using a lift-and-shift approach.

---

## 1) Prerequisites

### AWS
- An AWS account
- Region: recommended `us-east-1` (N. Virginia) to match many courses
- A domain name (optional, only needed if you want HTTPS with a custom DNS name)
- ACM certificate (optional, for HTTPS)

### Local machine (build host)
Install:
- Java **17**
- Maven **3.9.x**
- AWS CLI v2

Verify:
```bash
java -version
mvn -version
aws --version
```

---

## 2) AWS Components Overview

### EC2 instances (4)
- **db01**: MariaDB (MySQL-compatible) + schema
- **mc01**: Memcached
- **rmq01**: RabbitMQ
- **app01**: Tomcat 10 (Ubuntu 24.04) + vProfile WAR deployment

### Networking controls (Security Groups)
- **ALB SG**: inbound 80/443 from Internet
- **App SG**: inbound 8080 from ALB SG + SSH from your IP
- **Backend SG**: inbound 3306/11211/5672 from App SG + SSH from your IP + allow all within backend SG

### DNS
- Route 53 **Private Hosted Zone** (e.g. `vprofile.in`)
- A-records mapping service names to **private** IPs

### Storage
- S3 bucket (stores WAR artifact)

### IAM
- IAM user with S3 access (for your laptop to upload WAR)
- IAM role with S3 access attached to `app01` (so the instance can `aws s3 cp` without static keys)

---

## 3) Step-by-step

### Step A — Create key pair
EC2 → Key Pairs → Create key pair (PEM)

Keep it safe:
```bash
chmod 400 vprofile-prod-key.pem
```

---

### Step B — Create security groups

#### 1) Load Balancer SG (`vprofile-ELB-SG`)
Inbound rules:
- HTTP 80 from `0.0.0.0/0` and `::/0`
- HTTPS 443 from `0.0.0.0/0` and `::/0`

#### 2) App SG (`vprofile-app-sg`)
Inbound rules:
- TCP 8080 from `vprofile-ELB-SG`
- SSH 22 from **your public IP**

#### 3) Backend SG (`vprofile-backend-sg`)
Inbound rules:
- TCP 3306 from `vprofile-app-sg`
- TCP 11211 from `vprofile-app-sg`
- TCP 5672 from `vprofile-app-sg`
- SSH 22 from **your public IP**
- **All traffic** from **itself** (`vprofile-backend-sg`) — allows backend nodes to talk to each other

> Do NOT change outbound rules (keep default allow-all outbound).

---

### Step C — Launch EC2 instances with User Data

#### db01 (Amazon Linux 2023)
- Security group: `vprofile-backend-sg`
- User data: `userdata/mysql.sh`

#### mc01 (Amazon Linux 2023)
- Security group: `vprofile-backend-sg`
- User data: `userdata/memcache.sh`

#### rmq01 (Amazon Linux 2023)
- Security group: `vprofile-backend-sg`
- User data: `userdata/rabbitmq.sh`

#### app01 (Ubuntu 24.04)
- Security group: `vprofile-app-sg`
- User data: `userdata/tomcat_ubuntu.sh`

---

### Step D — Route 53 Private Hosted Zone

Route 53 → Hosted Zones → Create hosted zone
- Type: **Private hosted zone**
- Name: `vprofile.in` (example)
- VPC: select your VPC

Create A-records (private IPs):
- `db01.vprofile.in` → db01 private IP
- `mc01.vprofile.in` → mc01 private IP
- `rmq01.vprofile.in` → rmq01 private IP

Validate from app01:
```bash
ping -c 2 db01.vprofile.in
ping -c 2 mc01.vprofile.in
ping -c 2 rmq01.vprofile.in
```

---

### Step E — Build the WAR and upload to S3

#### 1) Edit application.properties in the vProfile source repo
Update the hosts (example):
- `db01.vprofile.in:3306`
- `mc01.vprofile.in:11211`
- `rmq01.vprofile.in:5672`

#### 2) Build
```bash
mvn clean install
ls -la target/*.war
```

#### 3) Upload to S3
Create an S3 bucket (unique name).
Configure your AWS CLI (IAM user keys):
```bash
aws configure
```

Upload:
```bash
aws s3 cp target/vprofile-v2.war s3://YOUR_BUCKET_NAME/
```

---

### Step F — Deploy on app01 (Tomcat)

Attach an IAM **role** (instance profile) with S3 access to app01.

Install AWS CLI on Ubuntu:
```bash
sudo snap install aws-cli --classic
aws --version
```

Download WAR:
```bash
aws s3 cp s3://YOUR_BUCKET_NAME/vprofile-v2.war /tmp/vprofile-v2.war
```

Deploy:
```bash
sudo systemctl stop tomcat10
sudo rm -rf /var/lib/tomcat10/webapps/ROOT
sudo cp /tmp/vprofile-v2.war /var/lib/tomcat10/webapps/ROOT.war
sudo systemctl start tomcat10
```

---

### Step G — Create Target Group + ALB

1) Target group
- Type: Instances
- Protocol: HTTP
- Port: **8080**
- Health check port: **8080**
- Register your app instance(s)

2) ALB
- Listener: 80 → target group
- (Optional) Listener: 443 → target group + ACM certificate
- SG: `vprofile-ELB-SG`
- Subnets: choose multiple AZs

(Optional) Add CNAME in your DNS provider pointing to ALB DNS name.

---

### Step H — Auto Scaling Group (ASG) for Tomcat layer

1) Create AMI from app01
2) Create Launch Template:
- AMI: your created AMI
- SG: `vprofile-app-sg`
- Key pair: your key
- Tags: `Name=vprofile-app`, `Project=vprofile`
3) Create ASG:
- Desired: 1 (or 2)
- Min: 1
- Max: 4
- Attach to the existing target group
- Enable ELB health checks
- Scaling policy: target tracking on CPU (example 50%)

Enable **stickiness** on the target group (recommended for this application).

---

## 4) Verification checklist

- Can you access the app via ALB DNS name?
- Target group shows instances **Healthy**
- Login works (DB connectivity)
- Cache test works (Memcache)
- Background/queue actions work (RabbitMQ)

See `docs/RUNBOOK.md` for command-by-command verification.

