# Fullstack Vue + NestJS + PostgreSQL on AWS

This repository contains a fullstack application built with:

- **Frontend**: Vue 3 (Vite)
- **Backend**: NestJS
- **Database**: PostgreSQL with sample address data

## Project Objective :
The objective of this project is to design and deploy a cloud-native fullstack application on AWS using modern frameworks and services. The system demonstrates end-to-end integration of a Vue.js frontend, a NestJS backend, and a PostgreSQL database, following best practices for scalability, reliability, and CI/CD automation.

# Project Goal :  
When you open the frontend, it calls the backend API which responds with: Hello {Name}, today is {Date}. Your registered address is: {Address}

The **name** and **address** come randomly from the database, while the **date** is generated dynamically.
---
## Two Deployment Approaches

I deployed the same app in **two different ways on AWS**, both using Terraform for infrastructure:

### 1. ECS / ALB / RDS (Approach 1)
- Frontend is built and stored in **S3**, delivered to the user via **CloudFront**
- Backend runs as a container on **ECS Fargate** behind an **Application Load Balancer**
- Database is an **RDS PostgreSQL instance** in private subnets
- Everything is deployed into a custom **VPC** across 2 AZs
- CI/CD is handled with **CodePipeline + CodeBuild**
- ECS service has **autoscaling** enabled (CPU, memory, requests per target)

### 2. Serverless (Approach 2)
- Frontend stays on **S3 + CloudFront**
- Backend runs as an **AWS Lambda** function exposed through **API Gateway**
- Database is **Aurora PostgreSQL Serverless v2** with **RDS Proxy** for connection pooling
- Uses **Secrets Manager** to fetch DB credentials
- CI/CD builds and deploys the Lambda code bundle automatically
- Scales down to very low cost when idle

---

## Local Development

Requirements:
- Node.js 20+
- Docker / Docker Compose
- PostgreSQL client (`psql`)

Run everything locally:


docker compose up -d

## We can test our local developments with this endpoints as below 
Frontend → http://localhost:5173
Backend → http://localhost:3000/greeting

## Terraform Deployment

Each approach has its own Terraform folder:

infra/ecs_rds
infra/serverless

## Useful terraform commands during infra provisioning 
terraform init -reconfigure
terraform plan -var-file=backend.tfvars
terraform apply -var-file=backend.tfvars
terraform destroy -var-file=backend.tfvars #Note : Once all deployments were deployed and tested please destroy 

## I split Terraform into modules for:
network, db, ecs_alb, cdn, cicd_backend, cicd_frontend, and serverless_api.

## CI/CD Pipelines

Frontend: GitHub → CodePipeline → CodeBuild → Build Vue → Upload to S3 → CloudFront invalidation
Backend ECS: GitHub → CodePipeline → Build Docker image → Push to ECR → Update ECS service
Backend Lambda: GitHub → CodePipeline → Bundle Lambda zip → Update Lambda function
This allows frontend and backend to be updated independently.

## Autoscaling

ECS tasks scale automatically on CPU, memory, or request load.
Aurora Serverless v2 scales database capacity automatically.
Lambda scales per request (with RDS Proxy to manage DB connections).

# Useful Commands to check the logs 

Check ECS logs:
<aws logs tail /ecs/fullstack-backend --since 10m --follow>
Check Lambda logs:
<aws logs tail "/aws/lambda/fullstack-sls-api" --since 5m --follow>


# Below command helps to Configure our AWS Acoount  
aws configure --profile fullstack-<Add account id>

export AWS_PROFILE=fullstack-<AccID here>
export AWS_DEFAULT_REGION=<Region here>

# Verify account identity now
aws sts get-caller-identity

# Verify the backend api with curl via load balancer and cloudfront 

curl -s https://d2bsfkopojhscg.cloudfront.net/api/greeting        ## Via cloudfront
curl -s http://fullstack-alb-518895826.eu-central-1.elb.amazonaws.com/greeting ## Via Loadbalancer

# Task1 
curl -s http://fullstack-alb-518895826.eu-central-1.elb.amazonaws.com/greeting | jq

# Task4
API="https://w14uyuaf9f.execute-api.eu-central-1.amazonaws.com"
curl -s "$API/api/greeting" | jq

```bash