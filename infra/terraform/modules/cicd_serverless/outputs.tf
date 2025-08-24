output "serverless_build_project" {
  value = aws_codebuild_project.serverless.name
}

output "serverless_pipeline_name" {
  value = aws_codepipeline.serverless.name
}
