# High-Availability Enterprise Cloud Architecture Using Terraform

##  Project Overview
This project programmatically deploys a highly available, load-balanced multi-tier web application architecture on **Amazon Web Services (AWS)** using **Terraform (Infrastructure as Code)**. The design ensures zero downtime and fault tolerance by distributing traffic across multiple AWS Availability Zones.

##  Architecture Design & Components
* **Virtual Private Cloud (VPC):** A custom network space (`10.0.0.0/16`) hosting all resources with DNS support enabled.
* **Multi-AZ Public Subnets:** Dual public subnet layers spanning `us-east-1a` and `us-east-1b` data centers to host public-facing infrastructure.
* **Application Load Balancer (ALB):** Sits at the public perimeter, acting as a reverse proxy to intercept incoming user requests and balance network load evenly.
* **Decoupled Security Layer:** Implements strict security group firewalls where compute nodes accept HTTP traffic *only* if origin-validated by the ALB.
* **Compute Tier (EC2):** Two automated Ubuntu Linux (`t3.micro`) server instances launched across independent availability zones, bootstrapped via **Bash startup user-data scripts** running Apache2.

##  Tech Stack & Skills Highlighted
* **Cloud Infrastructure:** Amazon Web Services (AWS) — VPC, Subnets, ALB, Target Groups, EC2
* **Infrastructure as Code (IaC):** Terraform (HCL)
* **OS & Automation:** Ubuntu Linux, Bash Shell Scripting
* **Architecture Style:** High-Availability (HA), Multi-AZ, Load Balancing

##  Step-by-Step Deployment Guide

### 1. Prerequisite Checks
Ensure your AWS CLI environment is active with your IAM Access Keys configured, and HashiCorp Terraform is running locally.

### 2. Execution Pipeline
To spin up or update this high-availability stack, execute the native Terraform lifecycle commands sequentially:

```bash
# Initialize workspace and pull down AWS registry plugins
terraform init

# Validate syntax rules across configuration scripts
terraform validate

# Perform a dry-run execution to review planned infrastructure updates
terraform plan

# Apply and execute modifications live on the AWS Cloud environment
terraform apply
```

##  Architecture Proof & Verification
The deployment was successfully validated via active AWS Target Group HTTP health checks, confirming that both ec2 compute targets maintain a green, active **Healthy** status badge.
