# High-Availability AWS Architecture with Terraform and GitHub Actions CI/CD

## Project Overview

This project provisions a highly available, load-balanced web application architecture on Amazon Web Services (AWS) using Terraform Infrastructure as Code (IaC). It uses multiple Availability Zones, an Application Load Balancer, and two EC2 web servers.

GitHub Actions automates Terraform initialization, validation, and planning. A manually triggered deployment workflow uses AWS OpenID Connect (OIDC) to authenticate to AWS without storing long-lived AWS access keys in GitHub repository secrets.

## Architecture and Components

- **Amazon VPC:** Custom network with CIDR `10.0.0.0/16` and DNS support enabled.
- **Public Subnets:** Subnets distributed across `us-east-1a` and `us-east-1b`.
- **Application Load Balancer (ALB):** Receives incoming HTTP traffic and distributes requests across registered web servers.
- **Security Groups:** Allows public HTTP traffic to the ALB while restricting EC2 HTTP ingress to the ALB security group.
- **Amazon EC2:** Two Ubuntu Linux `t3.micro` instances deployed across Availability Zones.
- **Apache2 and Bash:** EC2 user-data scripts install and configure the web server during startup.
- **Target Group and Health Checks:** Monitor web-server health and route requests to healthy targets.
- **Terraform:** Defines and provisions the AWS infrastructure.
- **GitHub Actions:** Automates Terraform validation and planning, with manual deployment.
- **AWS IAM OIDC:** Provides short-lived AWS credentials to GitHub Actions by assuming an IAM role.

## Technology Stack

- Amazon Web Services: VPC, EC2, Application Load Balancer, Target Groups, Security Groups
- Terraform and HashiCorp Configuration Language (HCL)
- Git and GitHub
- GitHub Actions
- AWS IAM and OpenID Connect (OIDC)
- Ubuntu Linux, Apache2, and Bash scripting

## CI/CD Workflow

1. Code changes are pushed to the `main` branch.
2. GitHub Actions checks out the repository and installs Terraform.
3. AWS credentials are obtained through GitHub OIDC.
4. Terraform initializes the working directory and validates the configuration.
5. Terraform generates an execution plan.
6. A user manually triggers the deployment workflow.
7. Terraform applies the plan and creates or updates AWS infrastructure.

## Deployment

### Prerequisites

- An AWS account with suitable IAM permissions.
- Terraform installed locally if running commands from a workstation.
- Git and a GitHub repository.
- GitHub Actions configured with AWS OIDC and an IAM role.
- A configured Terraform state backend or appropriate state-management procedure.

### Local Terraform Commands

Run these commands from the Terraform project directory:

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

Review the proposed changes before approving an apply. For CI/CD deployments, use the configured GitHub Actions workflow.

## Deployment Results

The project was successfully deployed and verified.

- Terraform reported **18 resources added**.
- The Application Load Balancer was created successfully.
- Both registered EC2 targets reached a healthy status.
- The web application was accessible through the ALB DNS endpoint.
- The GitHub Actions deployment workflow completed successfully.
- GitHub Actions authenticated to AWS using OIDC rather than long-lived AWS access keys.

## Key Skills Demonstrated

- AWS infrastructure provisioning and cloud networking.
- Terraform configuration, validation, planning, and deployment.
- Multi-AZ architecture and load balancing.
- EC2 bootstrapping using Bash and user-data scripts.
- Security-group design and traffic restrictions.
- GitHub Actions CI/CD automation.
- IAM trust policies and OIDC troubleshooting.
- Debugging AWS permission errors and validating deployments.

## Future Improvements

- Configure remote Terraform state in Amazon S3 with state locking.
- Apply least-privilege IAM permissions to the deployment role.
- Add Terraform formatting, linting, and security checks.
- Introduce deployment approvals and separate environments.
- Test application availability during an EC2 instance failure.
- Add monitoring, logging, and alerting.

## Cleanup

AWS resources can incur charges while they exist. After completing testing, run `terraform destroy` from the correct project directory when it is safe to remove the environment. Confirm the destruction plan before approving it, and verify that the resources have been removed afterward.
