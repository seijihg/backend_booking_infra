# CloudWatch Events and SNS Notifications for Pipeline

# CloudWatch Event Rule for Pipeline State Changes
resource "aws_cloudwatch_event_rule" "pipeline_state" {
  count = var.enable_notifications ? 1 : 0

  name        = "${var.app_name}-${var.environment}-pipeline-state"
  description = "Capture pipeline state changes"

  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      pipeline = [aws_codepipeline.main.name]
      state    = ["FAILED", "SUCCEEDED", "STARTED"]
    }
  })

  tags = var.tags
}

# CloudWatch Event Rule for Build State Changes
resource "aws_cloudwatch_event_rule" "build_state" {
  count = var.enable_notifications ? 1 : 0

  name        = "${var.app_name}-${var.environment}-build-state"
  description = "Capture build state changes"

  event_pattern = jsonencode({
    source      = ["aws.codebuild"]
    detail-type = ["CodeBuild Build State Change"]
    detail = {
      project-name = [aws_codebuild_project.main.name]
      build-status = ["FAILED", "SUCCEEDED", "STOPPED"]
    }
  })

  tags = var.tags
}

# CloudWatch Event Target for Pipeline Notifications
resource "aws_cloudwatch_event_target" "pipeline_sns" {
  count = var.enable_notifications && var.sns_topic_arn != "" ? 1 : 0

  rule      = aws_cloudwatch_event_rule.pipeline_state[0].name
  target_id = "SendToSNS"
  arn       = var.sns_topic_arn

  input_transformer {
    input_paths = {
      pipeline = "$.detail.pipeline"
      state    = "$.detail.state"
      execution = "$.detail.execution-id"
    }
    input_template = jsonencode({
      subject = "${var.environment} Pipeline <pipeline> is <state>"
      message = "Pipeline: <pipeline>\nState: <state>\nExecution ID: <execution>\nTime: ${timestamp()}"
    })
  }
}

# CloudWatch Event Target for Build Notifications
resource "aws_cloudwatch_event_target" "build_sns" {
  count = var.enable_notifications && var.sns_topic_arn != "" ? 1 : 0

  rule      = aws_cloudwatch_event_rule.build_state[0].name
  target_id = "SendToSNS"
  arn       = var.sns_topic_arn

  input_transformer {
    input_paths = {
      project = "$.detail.project-name"
      status  = "$.detail.build-status"
      id      = "$.detail.build-id"
    }
    input_template = jsonencode({
      subject = "${var.environment} Build <project> <status>"
      message = "Project: <project>\nStatus: <status>\nBuild ID: <id>\nTime: ${timestamp()}"
    })
  }
}

# CloudWatch Alarms for Pipeline Failures
resource "aws_cloudwatch_metric_alarm" "pipeline_failed" {
  count = var.enable_notifications ? 1 : 0

  alarm_name          = "${var.app_name}-${var.environment}-pipeline-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "PipelineExecutionFailure"
  namespace           = "AWS/CodePipeline"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Pipeline execution failed"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    PipelineName = aws_codepipeline.main.name
  }

  tags = var.tags
}

# CloudWatch Dashboard for Pipeline Metrics
resource "aws_cloudwatch_dashboard" "pipeline" {
  count = var.enable_notifications ? 1 : 0

  dashboard_name = "${var.app_name}-${var.environment}-pipeline"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/CodePipeline", "PipelineExecutionSuccess", { stat = "Sum", label = "Successful Executions" }],
            [".", "PipelineExecutionFailure", { stat = "Sum", label = "Failed Executions" }],
            ["AWS/CodeBuild", "SuccessfulBuilds", { stat = "Sum", label = "Successful Builds" }],
            [".", "FailedBuilds", { stat = "Sum", label = "Failed Builds" }]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Pipeline Execution Metrics"
          view   = "timeSeries"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/CodeBuild", "Duration", { stat = "Average", label = "Average Build Duration" }],
            [".", "Duration", { stat = "Maximum", label = "Max Build Duration" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Build Duration"
          view   = "timeSeries"
          yAxis = {
            left = {
              label = "Seconds"
            }
          }
        }
      }
    ]
  })
}