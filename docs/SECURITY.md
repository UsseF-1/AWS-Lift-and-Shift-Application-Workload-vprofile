# Security Notes

## Security Groups (recommended)

### ALB Security Group (vprofile-ELB-SG)
Inbound:
- 80 (HTTP) from 0.0.0.0/0 and ::/0
- 443 (HTTPS) from 0.0.0.0/0 and ::/0
Outbound:
- default allow-all outbound (to reach targets)

### App Security Group (vprofile-app-sg)
Inbound:
- 8080 from ALB SG only
- 22 from **your IP** only
Outbound:
- default allow-all outbound (to reach backend services and S3 if needed)

### Backend Security Group (vprofile-backend-sg)
Inbound:
- 3306 from App SG only
- 11211 from App SG only
- 5672 from App SG only
- 22 from your IP only
- All traffic from itself (backend SG) to allow backend-to-backend communication
Outbound:
- default allow-all outbound

---

## IAM Guidance

- **Do not** store AWS access keys on EC2 instances.
- Use **IAM roles** (instance profiles) for EC2 → S3 access.
- Use **least privilege** whenever possible:
  - Prefer bucket-scoped policies instead of `AmazonS3FullAccess` in real production.

---

## HTTPS

- Use ACM-managed certificates for ALB HTTPS listener.
- Configure your DNS CNAME record to point to ALB DNS name.

