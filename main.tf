resource "random_uuid" "zesty_external_id" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  region = var.region != "" ? var.region : data.aws_region.current.region
  values_content = [
    for p in zesty_account.result.account.products : p.values
    if p.name == "Kompass" && p.active == true
  ][0]
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
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2Access"
        Effect = "Allow"
        Action = [
          "ec2:List*",
          "ec2:Describe*",
          "elasticloadbalancing:Describe*",
          "autoscaling:Describe*"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "OrganizationsAccess"
        Effect = "Allow"
        Action = [
          "organizations:List*",
          "organizations:Describe*"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "ServiceQuotasAccess"
        Effect = "Allow"
        Action = [
          "servicequotas:ListServiceQuotas",
          "servicequotas:GetServiceQuota",
          "servicequotas:GetRequestedServiceQuotaChange"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "MetricsAccess"
        Effect = "Allow"
        Action = [
          "cloudwatch:List*",
          "cloudwatch:Describe*",
          "cloudwatch:GetMetricStatistics"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "SavingsPlansAccess"
        Effect = "Allow"
        Action = [
          "savingsplans:List*",
          "savingsplans:Describe*",
          "savingsplans:CreateSavingsPlan"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "CostExplorerAccess"
        Effect = "Allow"
        Action = [
          "ce:List*",
          "ce:Describe*",
          "ce:Get*"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "EKSAccess"
        Effect = "Allow"
        Action = [
          "eks:List*",
          "eks:Describe*"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "AthenaAccess"
        Effect = "Allow"
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "ReadAccessToAthenaCurDataViaGlue"
        Effect = "Allow"
        Action = [
          "glue:GetDatabase*",
          "glue:GetTable*",
          "glue:GetPartition*",
          "glue:GetUserDefinedFunction",
          "glue:BatchGetPartition"
        ]
        Resource = [
          "arn:aws:glue:*:*:catalog",
          "arn:aws:glue:*:*:database/${var.glue_db_name}*",
          "arn:aws:glue:*:*:table/${var.glue_db_name}*/*"
        ]
      },
      {
        Sid    = "AllowPricingListPriceLists"
        Effect = "Allow"
        Action = [
          "pricing:ListPriceLists"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "BCMDataExportsAccess"
        Effect = "Allow"
        Action = [
          "bcm-data-exports:ListExports",
          "bcm-data-exports:GetExport"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "CostAndUsageReportAccess"
        Effect = "Allow"
        Action = [
          "cur:DescribeReportDefinitions"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "S3AccessToCurBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.zesty_cur_bucket.arn,
          "${aws_s3_bucket.zesty_cur_bucket.arn}/*"
        ]
      }
    ]
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
        Sid = "AllowCURv1Write"
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
        Sid = "AllowBCMDataExportsWrite"
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
  name = var.glue_crawler_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "glue_crawler_policy" {
  name = var.glue_crawler_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.zesty_cur_bucket.arn,
          "${aws_s3_bucket.zesty_cur_bucket.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
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
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = aws_iam_policy.glue_crawler_policy.arn
}

resource "aws_glue_crawler" "zesty_cur_crawler" {
  name          = var.glue_crawler_name
  role          = aws_iam_role.glue_crawler_role.arn
  database_name = aws_glue_catalog_database.zesty_cur_db.name
  description   = "Crawler to auto-generate CUR table schema"
  
  catalog_target {
    database_name = aws_glue_catalog_database.zesty_cur_db.name
    tables = [aws_glue_catalog_table.cur.name]
  }

  schedule = "cron(0 1 * * ? *)"

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }
}

resource "aws_cur_report_definition" "zesty_cur" {
  report_name = var.cur_report_name
  time_unit = "HOURLY"
  format      = "Parquet"
  compression = "Parquet"

  s3_bucket = aws_s3_bucket.zesty_cur_bucket.bucket
  s3_region = local.region
  s3_prefix = "cur/${var.cur_report_name}"
  additional_schema_elements = [
    "RESOURCES",
    "SPLIT_COST_ALLOCATION_DATA"
  ]

  additional_artifacts = [
    "ATHENA"
  ]

  report_versioning = "OVERWRITE_REPORT"
}

resource "aws_glue_catalog_database" "zesty_cur_db" {
  name = var.glue_db_name
}

resource "aws_glue_catalog_table" "cur" {
  name          = var.glue_db_name
  database_name = aws_glue_catalog_database.zesty_cur_db.name
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
    "storage.location.template" = "s3://${aws_s3_bucket.zesty_cur_bucket.bucket}/cur/${var.cur_report_name}/${var.cur_report_name}/year=$${year}/month=$${month}/"

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
    location      = "s3://${aws_s3_bucket.zesty_cur_bucket.bucket}/cur/${var.cur_report_name}/${var.cur_report_name}/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }
  }
}

resource "aws_athena_workgroup" "zesty_athena" {
  name = var.athena_workgroup

  configuration {
    enforce_workgroup_configuration = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.zesty_cur_bucket.bucket}/athena-results/"
    }
  }
}


resource "zesty_account" "result" {
  account = {
    id             = data.aws_caller_identity.current.account_id
    region         = local.region
    cloud_provider = "AWS"
    role_arn       = aws_iam_role.zesty_iam_role.arn
    external_id    = random_uuid.zesty_external_id.result
    products       = var.products
    cur = {
      s3_bucket       = aws_s3_bucket.zesty_cur_bucket.bucket
      cur_export_name = aws_cur_report_definition.zesty_cur.report_name
      cur_type = "cur_v1"
    }
    athena = {
      athena_db        = aws_glue_catalog_database.zesty_cur_db.name
      athena_s3_bucket = aws_athena_workgroup.zesty_athena.configuration[0].result_configuration[0].output_location
      athena_project_id = data.aws_caller_identity.current.account_id
      athena_region = local.region
      athena_table = aws_glue_catalog_database.zesty_cur_db.name
      athena_workgroup = aws_athena_workgroup.zesty_athena.name
      athena_catalog = "AwsDataCatalog"

    }
  }
  depends_on = [aws_iam_role_policy.zesty_policy]
}

resource "local_file" "kompass_values" {
  count      = var.create_values_local_file ? 1 : 0
  content    = local.values_content
  filename   = var.values_yaml_filename
  depends_on = [zesty_account.result]
}

moved {
  from = local_file.kompass_values
  to   = local_file.kompass_values[1]
}
