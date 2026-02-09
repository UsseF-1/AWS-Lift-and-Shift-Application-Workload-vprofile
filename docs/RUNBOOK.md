# Runbook — Verification & Troubleshooting

## Instance login

### Amazon Linux 2023 (db01/mc01/rmq01)
```bash
ssh -i vprofile-prod-key.pem ec2-user@PUBLIC_IP
```

### Ubuntu 24.04 (app01)
```bash
ssh -i vprofile-prod-key.pem ubuntu@PUBLIC_IP
```

---

## Service checks

### db01 (MariaDB)
```bash
sudo systemctl status mariadb
mysql -u admin -p accounts
SHOW TABLES;
```

### mc01 (Memcached)
```bash
sudo systemctl status memcached
sudo ss -lntp | grep 11211
```

### rmq01 (RabbitMQ)
```bash
sudo systemctl status rabbitmq-server
sudo ss -lntp | grep 5672
```

### app01 (Tomcat)
```bash
sudo systemctl status tomcat10
sudo tail -n 200 /var/log/tomcat10/catalina.out
```

---

## DNS validation (from app01)
```bash
ping -c 2 db01.vprofile.in
ping -c 2 mc01.vprofile.in
ping -c 2 rmq01.vprofile.in
```

If DNS fails:
- Ensure Route 53 Hosted Zone is **Private**
- Ensure the Hosted Zone is associated with the correct **VPC**
- Ensure you used **private IPs** in the A records

---

## Target group unhealthy

Checklist:
1) Is Tomcat running?
2) App SG allows **8080 from ALB SG**
3) Target group health check port is **8080**
4) Instance is in the same VPC/subnets reachable by ALB

---

## Common mistakes

- Outbound rules modified (instances cannot download packages)
- Using public IPs in Route 53 private hosted zone records
- Wrong Linux user for SSH (Ubuntu vs Amazon Linux)
- Artifact deployed with wrong name (must be `ROOT.war` if you want it under `/`)

