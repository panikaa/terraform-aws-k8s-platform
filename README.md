# AWS Kubernetes Platform – Terraform Infrastructure (EKS + RDS + VPC + ALB)

This repository contains a fully production-grade **AWS Kubernetes Platform**, built entirely with **Terraform**.  
It is designed to demonstrate a real-world cloud & DevOps stack:

- **EKS** Kubernetes cluster  
- **RDS PostgreSQL** (production-ready DB)  
- **VPC** (public/private subnets, IGW, NAT)  
- **AWS Load Balancer Controller (ALB Ingress Controller)**  
- **Remote Terraform state in S3 + DynamoDB lock**  
- **Modular, scalable, enterprise-ready Terraform layout**

This environment is ideal for:

- Cloud DevOps/SRE portfolio projects  
- GitOps deployments (ArgoCD)  
- CI/CD rollout pipelines  
- Application hosting (e.g., demo-app-nodejs)  
- Cloud-native labs and training  

---

# 🚀 Features

### **Core AWS Infrastructure**
- Production-grade **VPC** with:
  - 3 public subnets  
  - 3 private subnets  
  - NAT Gateway  
  - Internet Gateway  
  - Proper subnet tags for EKS + ALB  

### **EKS (Elastic Kubernetes Service)**
- EKS Control Plane (v1.30)  
- Managed Node Groups  
- IRSA enabled (IAM Roles for Service Accounts)  
- Required SGs, IAM roles, and tags  
- Outputs for kubeconfig  

### **RDS PostgreSQL**
- PostgreSQL 14  
- `db.t3.micro` (dev) with ability to scale  
- Secrets stored in Secrets Manager  
- DB subnet group in private subnets  
- SG access restricted to EKS nodes only  

### **AWS Load Balancer Controller (ALB)**
- IAM role + policy + IRSA  
- Helm installation  
- Ingress class `alb`  
- Fully automated ALB provisioning  

---

# 📂 Repository Structure

```

terraform-aws-k8s-platform/
modules/
network/                # VPC, subnets, NAT, routes
eks/                    # EKS + node groups + IRSA
rds/                    # PostgreSQL + SG + secrets
alb-ingress-controller/ # IAM + serviceaccount + helm
envs/
dev/
main.tf
variables.tf
backend.tf
outputs.tf
prod/
main.tf
variables.tf
backend.tf
outputs.tf
global/
s3-remote-state/
main.tf               # optional script to bootstrap S3 bucket

````

This layout follows best practices used by large DevOps/SRE teams.

---

# 🧱 Architecture Diagram

```markdown
                     ┌───────────────────────────┐
                     │         Internet           │
                     └───────────────┬───────────┘
                                     │
                       ┌─────────────▼──────────────┐
                       │     AWS Load Balancer      │
                       │ (ALB Ingress Controller)   │
                       └─────────────┬──────────────┘
                                     │
                     ┌───────────────▼────────────────┐
                     │        Amazon EKS Cluster       │
                     │  - API Server                   │
                     │  - Managed Node Groups          │
                     └───────────────┬────────────────┘
                                     │
                     ┌───────────────▼────────────────┐
                     │         Worker Nodes            │
                     │   Pods, Services, Deployments   │
                     └───────────────┬────────────────┘
                                     │
                     ┌───────────────▼────────────────┐
                     │        Amazon RDS Postgres      │
                     │   Private subnet, SG restricted │
                     └─────────────────────────────────┘
````

---

# 🛠 Requirements

Before using this repository, ensure:

* Terraform ≥ 1.3
* AWS CLI configured (`aws configure`)
* IAM user with admin or appropriate permissions
* kubectl installed
* helm installed
* S3 bucket created for Terraform backend (or use provided module)

---

# 🏗 Deployment — Step by Step

## 1️⃣ Configure Terraform backend

`envs/dev/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-hcm-state"
    key            = "dev/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-hcm-lock"
    encrypt        = true
  }
}
```

Create bucket & DynamoDB table (once):

```
aws s3 mb s3://terraform-hcm-state
aws dynamodb create-table \
  --table-name terraform-hcm-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

---

## 2️⃣ Initialize Terraform

```
cd terraform-aws-k8s-platform/envs/dev
terraform init
```

---

## 3️⃣ Apply infrastructure

```
terraform plan
terraform apply
```

This will create:

* VPC
* Subnets
* NAT
* EKS
* Managed Node Group
* RDS
* ALB Controller IAM + helm deployment

Full provisioning takes **12–18 minutes**.

---

## 4️⃣ Connect kubectl to EKS

```
aws eks update-kubeconfig --region eu-central-1 --name hcm-dev
```

Check:

```
kubectl get nodes
```

---

# 🌐 Using ALB Ingress

Example Ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hcm
  annotations:
    kubernetes.io/ingress.class: alb
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hcm-frontend
            port:
              number: 80
```

Check ALB:

```
kubectl get ingress
```

---

# 🔒 RDS Credentials

Password is stored in Secrets Manager:

```
aws secretsmanager get-secret-value --secret-id rds-hcm-password
```

Database endpoint:

```
terraform output db_endpoint
```

Connection string example:

```
postgresql://postgres:<password>@<endpoint>:5432/hcm
```

---

# 🧹 Destroying the Environment

To avoid AWS costs:

```
terraform destroy
```

ALWAYS tear down when not using EKS/RDS — they are not free.

---

# 🐞 Troubleshooting

### ALB Controller Pending?

* Check IAM/IRSA annotations
* Ensure subnets have tags:

  ```
  kubernetes.io/role/elb = 1
  kubernetes.io/role/internal-elb = 1
  ```

### EKS nodes not joining cluster?

* IAM policies missing
* Bad subnet config
* Wrong kubectl context

### RDS cannot be reached?

* EKS node SG must be added to RDS SG
* DB subnet group must include private subnets only

---

# 📜 License

MIT License — free to use and extend.

---

# 🤝 Contributions

PRs welcome.
This repo is intentionally structured for easy expansion:

* ExternalDNS
* EFS CSI
* Karpenter
* Multi-AZ RDS
* CI/CD automation

---
