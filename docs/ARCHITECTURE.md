# Architecture Details

## Why Lift & Shift?
Lift & Shift means moving an existing workload to the cloud **with minimal changes**:
- Same services (Tomcat, DB, Memcached, RabbitMQ)
- Same application behavior
- AWS provides managed building blocks (ALB, ASG, S3, Route 53)

## Traffic Flow
1) User hits domain (CNAME → ALB DNS)
2) ALB terminates TLS (HTTPS) using ACM certificate
3) ALB forwards request to Tomcat targets on port 8080
4) Tomcat resolves backend hostnames via Route 53 Private DNS
5) Tomcat connects to:
   - db01:3306
   - mc01:11211
   - rmq01:5672

## Scaling
- Only the Tomcat layer is auto-scaled in this project.
- DB/Memcache/RMQ stay as single instances (classic lift & shift).
- Target Group stickiness is recommended for this app.

## Suggested improvements (optional)
- Replace DB instance with RDS
- Replace Memcache with ElastiCache
- Replace RabbitMQ with Amazon MQ
- Use EFS or S3 for shared assets if needed
- Full IaC (Terraform/CloudFormation)

