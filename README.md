# fullstack-vue-nest-postgres-aws-deployment

End-to-end fullstack demo with frontend (Vue), backend (NestJS), database (PostgreSQL), deployed on AWS with CI/CD pipeline


# Clean terraform local files (important after destroy) 
cd infra/terraform

# Dry-run — see what will be removed
find . -type d -name '.terraform' -prune -print
find . -type f \( -name 'terraform.tfstate' -o -name 'terraform.tfstate.backup' -o -name '.terraform.lock.hcl' \) -print

# Remove local Terraform work dirs + state/lock files
find . -type d -name '.terraform' -prune -exec rm -rf {} +
find . -type f -name 'terraform.tfstate' -delete
find . -type f -name 'terraform.tfstate.backup' -delete
find . -type f -name '.terraform.lock.hcl' -delete

# Note : Please check the connection status from AWS codestar to our github

🔹 Project Roadmap
1. Application Structure

Frontend (Vue 3, Vite)

Displays "Hello {Name}, today is {date}. Your registered address is: {Address}"

Fetches data from backend via AJAX /api/greeting

Backend (NestJS)

REST endpoint: /api/greeting → returns JSON

Generates current date, queries PostgreSQL for random record

Random record = {name, street, zip, city, country}

Database (PostgreSQL)

Table: addresses

Fields: id, name, street, zip, city, country

Seeded with random but realistic data (AI-generated)

## Subtask 1: AWS Deployment Plan

Frontend (Vue)

Option A (simple, cost-effective):

Build → store in S3 bucket (private)

Distribute via CloudFront (CDN, HTTPS, caching, global availability)

Backend (NestJS)

Option A (containerized, managed):

Deploy with ECS Fargate behind Application Load Balancer (ALB)

Pros: fully managed, auto-scaling, good for demo

Option B (serverless, cheaper):

Package backend as AWS Lambda (Node.js runtime)

Expose via API Gateway

Database (Postgres)

Option A (managed, production-grade):

Amazon RDS for PostgreSQL (multi-AZ optional, free tier eligible)

Option B (lightweight, cheaper for demo):

Aurora Serverless v2 (Postgres) – scales automatically, pay-per-use

Infrastructure Management

Use Terraform to provision:

VPC (2 AZs, public + private subnets)

S3 + CloudFront (frontend)

ECS + ALB or Lambda + API Gateway (backend)

RDS PostgreSQL (database)

🔹 Subtask 2: CI/CD Pipelines

Use AWS CodePipeline + CodeBuild (integrated with GitHub).

Frontend Pipeline

Trigger: push to main branch (frontend folder)

Build: npm run build → upload to S3

Post-build: CloudFront cache invalidation

Backend Pipeline

Trigger: push to main branch (backend folder)

Build: Dockerize NestJS → push to ECR

Deploy: Update ECS Fargate service (or redeploy Lambda)

Database

DB schema + seeding done via migrations (e.g., Prisma, TypeORM, or raw SQL migration scripts)

Seed triggered automatically on first run

🔹 Subtask 3: Scaling for High Traffic

Frontend

CloudFront automatically scales globally

S3 scales automatically (no bottleneck)

Backend

ECS Fargate → auto scaling based on CPU/Memory/RequestCount

ALB distributes traffic across containers

Or with Lambda → auto-scales seamlessly per request

Database

RDS with read replicas for horizontal read scaling

Aurora Serverless v2 for dynamic scaling (preferred for unpredictable workloads)

Caching layer (optional): Amazon ElastiCache (Redis)

## Subtask 4: Serverless Alternative

Serverless Stack:

Frontend: S3 + CloudFront (same)

Backend: Lambda + API Gateway (instead of ECS)

Database: Aurora Serverless v2 (instead of provisioned RDS)

Advantages

No servers to manage

Scales automatically

Lower idle cost (pay-per-use)

Faster setup for demo

Disadvantages

Cold starts on Lambda (latency for first requests)

Harder to run long-lived processes

Aurora Serverless costs can spike under load (not predictable)

Vendor lock-in

## Cost Considerations (Free Tier Friendly)

S3 + CloudFront → free/very cheap

ECS Fargate → costs for vCPU/memory, but free tier covers some

Lambda + API Gateway → cheaper for demo (100k+ requests free/month)

RDS PostgreSQL (db.t3.micro) → free tier eligible for 750 hrs/month

Aurora Serverless v2 → pay per ACU (scales better, but not always free)





## Approach 1: ECS Fargate + RDS PostgreSQL

Frontend: S3 + CloudFront

Backend: ECS Fargate (Dockerized NestJS) + ALB

Database: RDS PostgreSQL (multi-AZ optional)

Secrets: DB creds in Secrets Manager → ECS task fetches via task role

CI/CD: CodePipeline + CodeBuild (frontend + backend separately)

## Approach 2: Serverless (Lambda + Aurora Serverless v2)

Frontend: S3 + CloudFront (same)

Backend: AWS Lambda (NestJS bundled) + API Gateway

Database: Aurora Serverless v2 (Postgres)

Secrets: DB creds in Secrets Manager → Lambda fetches via IAM role

CI/CD: CodePipeline + CodeBuild (build → package → deploy Lambda)



# Configuring your AWS Acoount 
aws configure --profile fullstack-257394456514

export AWS_PROFILE=fullstack-257394456514
export AWS_DEFAULT_REGION=eu-central-1
# Verify account 
aws sts get-caller-identity

