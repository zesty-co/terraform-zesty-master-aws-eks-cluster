locals {
  cm_enabled             = var.cm_access_mode != "disabled"
  cm_full_access_enabled = var.cm_access_mode == "full"

  computed_products = concat(
    var.kompass_enabled ? [
      {
        name   = "Kompass"
        active = true
      }
    ] : [],
    local.cm_enabled ? [
      {
        name   = "CM"
        active = local.cm_full_access_enabled
      }
    ] : []
  )

  effective_products = var.products != null ? var.products : local.computed_products

  values_content = var.kompass_enabled ? try([
    for p in zesty_account.result.account.products : p.values
    if p.name == "Kompass" && p.active == true
  ][0], null) : null

  shared_policy_statements = [
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
      Action = var.kompass_enabled ? [
        "savingsplans:List*",
        "savingsplans:Describe*",
        "savingsplans:CreateSavingsPlan"
        ] : [
        "savingsplans:List*",
        "savingsplans:Describe*"
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
    }
  ]

  kompass_policy_statements = [
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
    }
  ]

  payer_policy_statements = [
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
      Action = var.kompass_enabled ? [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:GetBucketLocation"
        ] : [
        "s3:Get*",
        "s3:List*"
      ]
      Resource = [
        aws_s3_bucket.zesty_cur_bucket.arn,
        "${aws_s3_bucket.zesty_cur_bucket.arn}/*"
      ]
    }
  ]

  cm_full_policy_statements = [
    {
      Sid    = "EC2AccessCM"
      Effect = "Allow"
      Action = [
        "ec2:CreateReservedInstancesListing",
        "ec2:PurchaseReservedInstancesOffering",
        "ec2:PurchaseHostReservation",
        "ec2:GetReservedInstancesExchangeQuote",
        "ec2:AcceptReservedInstancesExchangeQuote",
        "ec2:CancelReservedInstancesListing",
        "ec2:ModifyReservedInstances"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "ServiceQuotasAccessCM"
      Effect = "Allow"
      Action = [
        "servicequotas:RequestServiceQuotaIncrease"
      ]
      Resource = ["*"]
    },
    {
      Sid    = "SavingsPlansAccessCM"
      Effect = "Allow"
      Action = [
        "savingsplans:*"
      ]
      Resource = ["*"]
    }
  ]

  zesty_policy_statements = concat(
    local.shared_policy_statements,
    var.kompass_enabled ? local.kompass_policy_statements : [],
    local.payer_policy_statements,
    local.cm_full_access_enabled ? local.cm_full_policy_statements : []
  )

  athena_account_payload = {
    athena_db         = one(aws_glue_catalog_database.zesty_cur_db[*].name)
    athena_s3_bucket  = one(aws_athena_workgroup.zesty_athena[*].configuration[0].result_configuration[0].output_location)
    athena_project_id = data.aws_caller_identity.current.account_id
    athena_region     = local.region
    athena_table      = one(aws_glue_catalog_database.zesty_cur_db[*].name)
    athena_workgroup  = one(aws_athena_workgroup.zesty_athena[*].name)
    athena_catalog    = "AwsDataCatalog"
  }

  zesty_account_base_payload = {
    id                 = data.aws_caller_identity.current.account_id
    region             = local.region
    cloud_provider     = "AWS"
    role_arn           = aws_iam_role.zesty_iam_role.arn
    external_id        = random_uuid.zesty_external_id.result
    storage_class_name = var.storage_class_name
    products           = local.effective_products
    cur = {
      s3_bucket       = aws_s3_bucket.zesty_cur_bucket.bucket
      cur_export_name = aws_cur_report_definition.zesty_cur.report_name
      cur_type        = "cur_v1"
    }
  }

  zesty_account_payload = merge(
    local.zesty_account_base_payload,
    var.kompass_enabled ? { athena = local.athena_account_payload } : {}
  )
}
