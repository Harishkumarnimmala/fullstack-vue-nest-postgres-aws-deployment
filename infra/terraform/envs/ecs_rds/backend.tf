terraform {
  backend "s3" {
    bucket         = "tf-state-257394456514-eu-central-1"
    key            = "ecs-rds/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "tf-locks-257394456514-eu-central-1"
    encrypt        = true
  }
}
