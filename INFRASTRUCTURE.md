
# 🌐 **How These Repositories Work Together**

This project is split into three separate repositories, each responsible for a different layer of the platform.
Together, they form a complete, production-ready **AWS → Kubernetes → GitOps** delivery pipeline.

---

## 🔧 **1. terraform-aws-k8s-platform — Infrastructure Layer (IaC)**

This repository provisions the entire cloud environment using Terraform:

* VPC, subnets, routing
* EKS cluster
* RDS/PostgreSQL
* ALB + target groups
* IAM roles, OIDC provider
* AWS Secrets Manager (for Kubernetes External Secrets)

**Output of this repository is a fully bootstrapped EKS cluster**, ready to be managed declaratively through GitOps.

---

## 📦 **2. gitops-cluster-config — Runtime & GitOps Layer**

This repository defines the **desired state** of the EKS cluster:

* ArgoCD applications and sync rules
* Helm releases for system components
* Ingress, HPA, services
* External Secrets Operator
* Node/pod-level configurations
* Deployment definitions for each environment (dev/staging/prod)

ArgoCD continuously reconciles this repository with the live cluster, ensuring that **Kubernetes always matches what is stored in Git**.

Terraform provides the cluster →
GitOps manages the cluster →
Everything flows through pull requests.

---

## 🚀 **3. demo-app-nodejs — Application Layer (CI/CD + Helm)**

This repository contains the sample Node.js application:

* Source code
* Dockerfile (multi-stage)
* Helm chart
* GitHub Actions pipeline:

  * build
  * test
  * scan
  * push to ECR
  * version bump → GitOps repo update

The GitOps update step automatically changes the image version in the `gitops-cluster-config` repository.
ArgoCD detects the change and deploys the new version to the EKS cluster.

---

# 🔄 **End-to-End Delivery Flow**

```
[1] terraform-aws-k8s-platform
        │
        ▼
Creates EKS cluster + AWS infrastructure
        │
        ▼
[2] gitops-cluster-config
Declaratively manages cluster state via ArgoCD
        │
        ▼
[3] demo-app-nodejs
Builds & pushes image → updates GitOps repo
        │
        ▼
ArgoCD applies new release to the cluster
```

---
