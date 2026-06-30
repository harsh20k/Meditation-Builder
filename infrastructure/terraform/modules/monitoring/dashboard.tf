locals {
  region = data.aws_region.current.name

  api_lambda_names = [
    "${var.name_prefix}-get-routines",
    "${var.name_prefix}-post-routine",
    "${var.name_prefix}-get-routine",
    "${var.name_prefix}-delete-routine",
    "${var.name_prefix}-like-routine",
    "${var.name_prefix}-unlike-routine",
    "${var.name_prefix}-import-routine",
    "${var.name_prefix}-get-recommendations",
    "${var.name_prefix}-search",
    "${var.name_prefix}-post-activity",
    "${var.name_prefix}-presign-audio-upload",
  ]

  async_lambda_names = [
    "${var.name_prefix}-bedrock-tagger",
    "${var.name_prefix}-typesense-indexer",
    "${var.name_prefix}-like-flush",
  ]

  cache_lambda_names = [
    "${var.name_prefix}-get-routines",
    "${var.name_prefix}-get-routine",
    "${var.name_prefix}-get-recommendations",
    "${var.name_prefix}-like-routine",
    "${var.name_prefix}-unlike-routine",
    "${var.name_prefix}-like-flush",
    "${var.name_prefix}-post-activity",
  ]
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name_prefix}-ops"

  dashboard_body = jsonencode({
    widgets = [
      # ── API Gateway ──────────────────────────────────────────────
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "## API Gateway — `${var.api_gateway_name}`"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 8
        height = 6
        properties = {
          title  = "Request Count"
          region = local.region
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiName", var.api_gateway_name],
          ]
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 1
        width  = 8
        height = 6
        properties = {
          title  = "Latency (p50 / p95 / p99)"
          region = local.region
          metrics = [
            ["AWS/ApiGateway", "Latency", "ApiName", var.api_gateway_name, { stat = "p50", label = "p50" }],
            ["...", { stat = "p95", label = "p95" }],
            ["...", { stat = "p99", label = "p99" }],
          ]
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 1
        width  = 8
        height = 6
        properties = {
          title  = "4xx / 5xx Errors"
          region = local.region
          metrics = [
            ["AWS/ApiGateway", "4XXError", "ApiName", var.api_gateway_name, { color = "#ff7f0e" }],
            ["AWS/ApiGateway", "5XXError", "ApiName", var.api_gateway_name, { color = "#d62728" }],
          ]
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
        }
      },

      # ── Lambda API routes ────────────────────────────────────────
      {
        type   = "text"
        x      = 0
        y      = 7
        width  = 24
        height = 1
        properties = {
          markdown = "## Lambda — API Routes"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 12
        height = 6
        properties = {
          title  = "Invocations"
          region = local.region
          metrics = [
            for fn in local.api_lambda_names : ["AWS/Lambda", "Invocations", "FunctionName", fn]
          ]
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 8
        width  = 12
        height = 6
        properties = {
          title  = "Errors"
          region = local.region
          metrics = [
            for fn in local.api_lambda_names : ["AWS/Lambda", "Errors", "FunctionName", fn]
          ]
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 14
        width  = 12
        height = 6
        properties = {
          title  = "Duration p95 (ms)"
          region = local.region
          metrics = [
            for fn in local.api_lambda_names : ["AWS/Lambda", "Duration", "FunctionName", fn, { stat = "p95" }]
          ]
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 14
        width  = 12
        height = 6
        properties = {
          title  = "Throttles & Concurrent Executions"
          region = local.region
          metrics = [
            for fn in local.api_lambda_names : ["AWS/Lambda", "Throttles", "FunctionName", fn]
          ]
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
        }
      },

      # ── Async workers ────────────────────────────────────────────
      {
        type   = "text"
        x      = 0
        y      = 20
        width  = 24
        height = 1
        properties = {
          markdown = "## Async Workers — bedrock-tagger · typesense-indexer · like-flush"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 21
        width  = 8
        height = 6
        properties = {
          title  = "Invocations"
          region = local.region
          metrics = [
            for fn in local.async_lambda_names : ["AWS/Lambda", "Invocations", "FunctionName", fn]
          ]
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 21
        width  = 8
        height = 6
        properties = {
          title  = "Errors"
          region = local.region
          metrics = [
            for fn in local.async_lambda_names : ["AWS/Lambda", "Errors", "FunctionName", fn]
          ]
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 21
        width  = 8
        height = 6
        properties = {
          title  = "Duration p95 (ms)"
          region = local.region
          metrics = [
            for fn in local.async_lambda_names : ["AWS/Lambda", "Duration", "FunctionName", fn, { stat = "p95" }]
          ]
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 27
        width  = 12
        height = 6
        properties = {
          title  = "Iterator Age — SQS / DynamoDB Stream lag (ms)"
          region = local.region
          metrics = [
            ["AWS/Lambda", "IteratorAge", "FunctionName", "${var.name_prefix}-bedrock-tagger", { stat = "Maximum", label = "bedrock-tagger (SQS)" }],
            ["AWS/Lambda", "IteratorAge", "FunctionName", "${var.name_prefix}-typesense-indexer", { stat = "Maximum", label = "typesense-indexer (DDB stream)" }],
          ]
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 27
        width  = 12
        height = 6
        properties = {
          title  = "like-flush — Invocations & Errors"
          region = local.region
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.name_prefix}-like-flush"],
            ["AWS/Lambda", "Errors", "FunctionName", "${var.name_prefix}-like-flush", { yAxis = "right" }],
          ]
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
        }
      },

      # ── Tag generation (Bedrock + SQS) ─────────────────────────
      {
        type   = "text"
        x      = 0
        y      = 33
        width  = 24
        height = 1
        properties = {
          markdown = "## Tag Generation — Bedrock + SQS (`${var.bedrock_tagging_queue_name}`)"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 34
        width  = 8
        height = 6
        properties = {
          title  = "SQS — Messages Visible & In Flight"
          region = local.region
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.bedrock_tagging_queue_name, { label = "visible" }],
            ["AWS/SQS", "ApproximateNumberOfMessagesNotVisible", "QueueName", var.bedrock_tagging_queue_name, { label = "in flight" }],
          ]
          stat   = "Maximum"
          period = 60
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 34
        width  = 8
        height = 6
        properties = {
          title  = "SQS — Throughput (sent / received / deleted)"
          region = local.region
          metrics = [
            ["AWS/SQS", "NumberOfMessagesSent", "QueueName", var.bedrock_tagging_queue_name, { label = "sent" }],
            ["AWS/SQS", "NumberOfMessagesReceived", "QueueName", var.bedrock_tagging_queue_name, { label = "received" }],
            ["AWS/SQS", "NumberOfMessagesDeleted", "QueueName", var.bedrock_tagging_queue_name, { label = "deleted" }],
          ]
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 34
        width  = 8
        height = 6
        properties = {
          title  = "SQS — Oldest Message Age (s)"
          region = local.region
          metrics = [
            ["AWS/SQS", "ApproximateAgeOfOldestMessage", "QueueName", var.bedrock_tagging_queue_name],
          ]
          stat   = "Maximum"
          period = 60
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 40
        width  = 8
        height = 6
        properties = {
          title  = "DLQ — `${var.bedrock_tagging_dlq_name}`"
          region = local.region
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.bedrock_tagging_dlq_name, { color = "#d62728" }],
            ["AWS/SQS", "NumberOfMessagesReceived", "QueueName", var.bedrock_tagging_dlq_name, { label = "received" }],
          ]
          stat   = "Maximum"
          period = 60
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 40
        width  = 8
        height = 6
        properties = {
          title  = "Bedrock — Invocations & Errors"
          region = local.region
          metrics = [
            ["AWS/Bedrock", "Invocations", "ModelId", var.bedrock_model_id, { label = "invocations" }],
            ["AWS/Bedrock", "InvocationClientErrors", "ModelId", var.bedrock_model_id, { label = "client errors", color = "#ff7f0e" }],
            ["AWS/Bedrock", "InvocationServerErrors", "ModelId", var.bedrock_model_id, { label = "server errors", color = "#d62728" }],
          ]
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 40
        width  = 8
        height = 6
        properties = {
          title  = "Bedrock — Latency & Tokens"
          region = local.region
          metrics = [
            ["AWS/Bedrock", "InvocationLatency", "ModelId", var.bedrock_model_id, { stat = "p95", label = "latency p95" }],
            ["AWS/Bedrock", "InputTokenCount", "ModelId", var.bedrock_model_id, { stat = "Sum", label = "input tokens", yAxis = "right" }],
            ["AWS/Bedrock", "OutputTokenCount", "ModelId", var.bedrock_model_id, { stat = "Sum", label = "output tokens", yAxis = "right" }],
          ]
          period = 300
          view   = "timeSeries"
        }
      },

      # ── Search (Typesense) ───────────────────────────────────────
      {
        type   = "text"
        x      = 0
        y      = 46
        width  = 24
        height = 1
        properties = {
          markdown = "## Search — Typesense (`${var.typesense_instance_id}`) + search Lambda"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 47
        width  = 8
        height = 6
        properties = {
          title  = "search Lambda — Invocations & Errors"
          region = local.region
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.name_prefix}-search"],
            ["AWS/Lambda", "Errors", "FunctionName", "${var.name_prefix}-search", { yAxis = "right" }],
            ["AWS/Lambda", "Duration", "FunctionName", "${var.name_prefix}-search", { stat = "p95", label = "duration p95", yAxis = "right" }],
          ]
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 47
        width  = 8
        height = 6
        properties = {
          title  = "typesense-indexer — Invocations & Errors"
          region = local.region
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.name_prefix}-typesense-indexer"],
            ["AWS/Lambda", "Errors", "FunctionName", "${var.name_prefix}-typesense-indexer", { yAxis = "right" }],
            ["AWS/Lambda", "Duration", "FunctionName", "${var.name_prefix}-typesense-indexer", { stat = "p95", label = "duration p95", yAxis = "right" }],
          ]
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 47
        width  = 8
        height = 6
        properties = {
          title  = "Typesense EC2 — Status Checks"
          region = local.region
          metrics = [
            ["AWS/EC2", "StatusCheckFailed", "InstanceId", var.typesense_instance_id, { color = "#d62728" }],
            ["AWS/EC2", "StatusCheckFailed_Instance", "InstanceId", var.typesense_instance_id],
            ["AWS/EC2", "StatusCheckFailed_System", "InstanceId", var.typesense_instance_id],
          ]
          stat   = "Maximum"
          period = 60
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 53
        width  = 12
        height = 6
        properties = {
          title  = "Typesense EC2 — CPU & Network"
          region = local.region
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", var.typesense_instance_id, { label = "CPU %" }],
            ["AWS/EC2", "NetworkIn", "InstanceId", var.typesense_instance_id, { stat = "Sum", label = "network in", yAxis = "right" }],
            ["AWS/EC2", "NetworkOut", "InstanceId", var.typesense_instance_id, { stat = "Sum", label = "network out", yAxis = "right" }],
          ]
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 53
        width  = 12
        height = 6
        properties = {
          title  = "Typesense EC2 — Disk Read/Write Ops"
          region = local.region
          metrics = [
            ["AWS/EC2", "DiskReadOps", "InstanceId", var.typesense_instance_id],
            ["AWS/EC2", "DiskWriteOps", "InstanceId", var.typesense_instance_id],
          ]
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
        }
      },

      # ── Cache (Redis) ────────────────────────────────────────────
      {
        type   = "text"
        x      = 0
        y      = 59
        width  = 24
        height = 1
        properties = {
          markdown = "## Cache — ElastiCache Redis (`${var.redis_cluster_id}`)"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 60
        width  = 8
        height = 6
        properties = {
          title  = "CPU & Memory"
          region = local.region
          metrics = [
            ["AWS/ElastiCache", "CPUUtilization", "CacheClusterId", var.redis_cluster_id, { label = "CPU %" }],
            ["AWS/ElastiCache", "DatabaseMemoryUsagePercentage", "CacheClusterId", var.redis_cluster_id, { label = "memory %" }],
          ]
          stat   = "Average"
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 60
        width  = 8
        height = 6
        properties = {
          title  = "Connections & Evictions"
          region = local.region
          metrics = [
            ["AWS/ElastiCache", "CurrConnections", "CacheClusterId", var.redis_cluster_id, { label = "connections" }],
            ["AWS/ElastiCache", "Evictions", "CacheClusterId", var.redis_cluster_id, { stat = "Sum", label = "evictions", color = "#d62728" }],
            ["AWS/ElastiCache", "Reclaimed", "CacheClusterId", var.redis_cluster_id, { stat = "Sum", label = "reclaimed" }],
          ]
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 60
        width  = 8
        height = 6
        properties = {
          title  = "Cache Hits / Misses"
          region = local.region
          metrics = [
            ["AWS/ElastiCache", "CacheHits", "CacheClusterId", var.redis_cluster_id, { stat = "Sum", label = "hits" }],
            ["AWS/ElastiCache", "CacheMisses", "CacheClusterId", var.redis_cluster_id, { stat = "Sum", label = "misses" }],
          ]
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 66
        width  = 12
        height = 6
        properties = {
          title  = "Redis Network I/O"
          region = local.region
          metrics = [
            ["AWS/ElastiCache", "NetworkBytesIn", "CacheClusterId", var.redis_cluster_id, { stat = "Sum" }],
            ["AWS/ElastiCache", "NetworkBytesOut", "CacheClusterId", var.redis_cluster_id, { stat = "Sum" }],
          ]
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 66
        width  = 12
        height = 6
        properties = {
          title  = "Cache-Heavy Lambdas — Invocations"
          region = local.region
          metrics = [
            for fn in local.cache_lambda_names : ["AWS/Lambda", "Invocations", "FunctionName", fn]
          ]
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
        }
      },

      # ── DynamoDB ─────────────────────────────────────────────────
      {
        type   = "text"
        x      = 0
        y      = 72
        width  = 24
        height = 1
        properties = {
          markdown = "## DynamoDB — `${var.dynamodb_table_name}`"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 73
        width  = 8
        height = 6
        properties = {
          title  = "Consumed Read / Write Capacity"
          region = local.region
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", var.dynamodb_table_name],
            ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", "TableName", var.dynamodb_table_name],
          ]
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 73
        width  = 8
        height = 6
        properties = {
          title  = "Throttled & System Errors"
          region = local.region
          metrics = [
            ["AWS/DynamoDB", "ThrottledRequests", "TableName", var.dynamodb_table_name, { color = "#d62728" }],
            ["AWS/DynamoDB", "SystemErrors", "TableName", var.dynamodb_table_name],
            ["AWS/DynamoDB", "UserErrors", "TableName", var.dynamodb_table_name],
          ]
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 73
        width  = 8
        height = 6
        properties = {
          title  = "Successful Request Latency (p95)"
          region = local.region
          metrics = [
            ["AWS/DynamoDB", "SuccessfulRequestLatency", "TableName", var.dynamodb_table_name, "Operation", "GetItem", { stat = "p95", label = "GetItem" }],
            ["AWS/DynamoDB", "SuccessfulRequestLatency", "TableName", var.dynamodb_table_name, "Operation", "Query", { stat = "p95", label = "Query" }],
            ["AWS/DynamoDB", "SuccessfulRequestLatency", "TableName", var.dynamodb_table_name, "Operation", "PutItem", { stat = "p95", label = "PutItem" }],
          ]
          period = 300
          view   = "timeSeries"
        }
      },

      # ── Recent errors (log insights) ─────────────────────────────
      {
        type   = "text"
        x      = 0
        y      = 79
        width  = 24
        height = 1
        properties = {
          markdown = "## Recent Lambda Errors (all handlers)"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 80
        width  = 24
        height = 6
        properties = {
          title  = "Error & Exception Log Lines (last 24h)"
          region = local.region
          view   = "table"
          query  = "SOURCE '/aws/lambda/${var.name_prefix}-bedrock-tagger' | SOURCE '/aws/lambda/${var.name_prefix}-typesense-indexer' | SOURCE '/aws/lambda/${var.name_prefix}-search' | SOURCE '/aws/lambda/${var.name_prefix}-like-flush' | SOURCE '/aws/lambda/${var.name_prefix}-post-routine' | fields @timestamp, @logStream, @message | filter @message like /(?i)(error|exception|failed|traceback)/ | sort @timestamp desc | limit 50"
        }
      },
    ]
  })
}
