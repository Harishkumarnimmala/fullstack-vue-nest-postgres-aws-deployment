terraform {
  backend "s3" {
    bucket         = "tf-state-257394456514-eu-central-1"
    key            = "serverless/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "tf-locks-257394456514-eu-central-1"
    encrypt        = true
  }

  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}
