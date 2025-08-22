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