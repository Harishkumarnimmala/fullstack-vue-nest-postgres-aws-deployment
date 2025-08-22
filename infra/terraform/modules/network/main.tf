module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.project}-vpc"
  cidr = "10.0.0.0/16"
  azs  = ["${var.region}a", "${var.region}b"]

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway   = false
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags                = var.tags
  vpc_tags            = merge(var.tags, { Name = "${var.project}-vpc" })
  public_subnet_tags  = merge(var.tags, { Name = "${var.project}-public" })
  private_subnet_tags = merge(var.tags, { Name = "${var.project}-private" })
}
