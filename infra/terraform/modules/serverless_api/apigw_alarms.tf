resource "aws_cloudwatch_metric_alarm" "apigw_5xx" {
  alarm_name          = "${var.project}-sls-apigw-5xx"
  alarm_description   = "HTTP API ${var.project} has 1+ 5XX responses in 1 minute"
  namespace           = "AWS/ApiGateway"
  metric_name         = "5XXError"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = aws_apigatewayv2_api.http.id
    Stage = "$default"
  }

  alarm_actions = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
  ok_actions    = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]

  tags = local.common_tags
}
