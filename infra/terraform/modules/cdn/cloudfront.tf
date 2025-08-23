# CloudFront + OAC (Origin Access Control) for private S3, plus /api/* to ALB

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project}-oac"
  description                       = "OAC for ${var.project} S3 frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  price_class         = var.price_class
  default_root_object = var.index_document

  # S3 origin (frontend)
  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = "s3-frontend"

    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id

    # provider still requires this block; keep empty OAI string with OAC
    s3_origin_config {
      origin_access_identity = ""
    }
  }

  # ALB origin (backend)
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "alb-backend"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default = serve SPA from S3
  default_cache_behavior {
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 0
    default_ttl = 300
    max_ttl     = 86400
  }

  # Route /healthz to ALB (uncached), so health works via CDN too
  ordered_cache_behavior {
    path_pattern           = "/healthz"
    target_origin_id       = "alb-backend"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
      headers = ["*"]
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }


  # Route API calls to ALB, effectively un-cached
  ordered_cache_behavior {
    path_pattern           = var.api_path_pattern # e.g., /api/*
    target_origin_id       = "alb-backend"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]

    forwarded_values {
      query_string = true
      cookies { forward = "all" }
      headers = ["*"]
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = merge(var.tags, {
    Project   = var.project
    Stack     = "cdn"
    Component = "cloudfront"
  })
}

# Allow this CloudFront distribution (via OAC) to read from the bucket
data "aws_iam_policy_document" "frontend_bucket" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.frontend_bucket.json

  depends_on = [aws_cloudfront_distribution.this]
}
