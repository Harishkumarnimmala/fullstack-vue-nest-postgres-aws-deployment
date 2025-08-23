module "cdn" {
  source = "../../modules/cdn"

  project      = var.project
  alb_dns_name = module.compute.alb_dns_name
  price_class  = "PriceClass_100"

  tags = {
    Environment = "ecs-rds"
  }
}
