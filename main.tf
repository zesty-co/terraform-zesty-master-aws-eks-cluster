resource "random_uuid" "zesty_external_id" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  region = var.region != "" ? var.region : data.aws_region.current.region
}

resource "aws_iam_role" "zesty_iam_role" {
  name                 = var.role_name
  max_session_duration = var.max_session_duration

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          AWS = var.trusted_principal
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = random_uuid.zesty_external_id.result
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "zesty_policy" {
  name = var.policy_name
  role = aws_iam_role.zesty_iam_role.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.zesty_policy_statements
  })
}

resource "aws_s3_bucket" "zesty_cur_bucket" {
  bucket        = "${var.cur_s3_bucket}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "cur_bucket" {
  bucket = aws_s3_bucket.zesty_cur_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_policy" "cur_bucket_policy" {
  bucket = aws_s3_bucket.zesty_cur_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCURv1Write"
        Effect = "Allow"
        Principal = {
          Service = "billingreports.amazonaws.com"
        }
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.zesty_cur_bucket.arn,
          "${aws_s3_bucket.zesty_cur_bucket.arn}/*"
        ]
      },
      {
        Sid    = "AllowBCMDataExportsWrite"
        Effect = "Allow"
        Principal = {
          Service = [
            "bcm-data-exports.amazonaws.com",
            "billing.amazonaws.com"
          ]
        }
        Action = [
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.zesty_cur_bucket.arn,
          "${aws_s3_bucket.zesty_cur_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "glue_crawler_role" {
  count = var.kompass_enabled ? 1 : 0

  name = var.glue_crawler_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "glue_crawler_policy" {
  count = var.kompass_enabled ? 1 : 0

  name = var.glue_crawler_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.zesty_cur_bucket.arn,
          "${aws_s3_bucket.zesty_cur_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:BatchGetPartition",
          "glue:CreateTable",
          "glue:UpdateTable",
          "glue:CreatePartition",
          "glue:UpdatePartition",
          "glue:BatchCreatePartition"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:*:*:/aws-glue/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_glue_policy" {
  count = var.kompass_enabled ? 1 : 0

  role       = aws_iam_role.glue_crawler_role[0].name
  policy_arn = aws_iam_policy.glue_crawler_policy[0].arn
}

resource "aws_glue_crawler" "zesty_cur_crawler" {
  count = var.kompass_enabled ? 1 : 0

  name          = var.glue_crawler_name
  role          = aws_iam_role.glue_crawler_role[0].arn
  database_name = aws_glue_catalog_database.zesty_cur_db[0].name
  description   = "Crawler to auto-generate Zesty CUR table schema"

  catalog_target {
    database_name = aws_glue_catalog_database.zesty_cur_db[0].name
    tables        = [aws_glue_catalog_table.cur[0].name]
  }

  schedule = "cron(0 1 * * ? *)"

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }
  lifecycle {
    ignore_changes = [configuration]
  }
  depends_on = [aws_glue_catalog_table.cur]

}

resource "aws_cur_report_definition" "zesty_cur" {
  report_name = var.cur_report_name
  time_unit   = "HOURLY"
  format      = "Parquet"
  compression = "Parquet"

  s3_bucket = aws_s3_bucket.zesty_cur_bucket.bucket
  s3_region = local.region
  s3_prefix = "cur"
  additional_schema_elements = [
    "RESOURCES",
    "SPLIT_COST_ALLOCATION_DATA"
  ]

  additional_artifacts = var.kompass_enabled ? ["ATHENA"] : []

  report_versioning = "OVERWRITE_REPORT"
}

resource "aws_glue_catalog_database" "zesty_cur_db" {
  count = var.kompass_enabled ? 1 : 0

  name = var.glue_db_name
}

resource "aws_glue_catalog_table" "cur" {
  count = var.kompass_enabled ? 1 : 0

  name          = var.glue_db_name
  database_name = aws_glue_catalog_database.zesty_cur_db[0].name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    classification              = "parquet"
    compressionType             = "parquet"
    EXTERNAL                    = "TRUE"
    "projection.enabled"        = "true"
    "projection.year.type"      = "integer"
    "projection.year.range"     = "2000,2100"
    "projection.month.type"     = "integer"
    "projection.month.range"    = "1,12"
    "storage.location.template" = "s3://${aws_s3_bucket.zesty_cur_bucket.bucket}/${aws_cur_report_definition.zesty_cur.s3_prefix}/${var.cur_report_name}/${var.cur_report_name}/year=$${year}/month=$${month}/"

  }
  partition_keys {
    name = "year"
    type = "int"
  }

  partition_keys {
    name = "month"
    type = "int"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.zesty_cur_bucket.bucket}/${aws_cur_report_definition.zesty_cur.s3_prefix}/${var.cur_report_name}/${var.cur_report_name}/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }
  }
}

resource "aws_athena_workgroup" "zesty_athena" {
  count = var.kompass_enabled ? 1 : 0

  name          = var.athena_workgroup
  force_destroy = true

  configuration {
    enforce_workgroup_configuration = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.zesty_cur_bucket.bucket}/${var.athena_result_directory}/"
    }
  }
}

resource "time_sleep" "wait_for_iam" {
  create_duration = var.iam_propagation_delay

  triggers = {
    role_policy   = aws_iam_role.zesty_iam_role.assume_role_policy
    inline_policy = aws_iam_role_policy.zesty_policy.policy
  }

  depends_on = [aws_iam_role_policy.zesty_policy]
}

resource "zesty_account" "result" {
  account = local.zesty_account_payload

  depends_on = [aws_iam_role_policy.zesty_policy, time_sleep.wait_for_iam]
}

resource "local_file" "kompass_values" {
  count      = var.kompass_enabled && var.create_values_local_file ? 1 : 0
  content    = coalesce(local.values_content, "")
  filename   = var.values_yaml_filename
  depends_on = [zesty_account.result]
}
