terraform {
  backend "s3" {
    bucket         = "tfstate-257394456514-eu-central-1"
    key            = "fullstack/dev/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "tf-locks-fullstack"
    encrypt        = true
  }
}
