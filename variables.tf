variable "role_name" {
  description = "IAM role name"
  type        = string
  default     = "ZestyIamRole"
}

variable "region" {
  description = "AWS region"
  default     = ""
  type        = string
}

variable "policy_name" {
  description = "IAM policy name"
  type        = string
  default     = "ZestyPolicy"
}

variable "max_session_duration" {
  description = "Maximum session duration of the assumed role (in seconds)"
  type        = number
  default     = 43200
}

variable "products" {
  description = "List of all products to enable"
  type        = list(map(any))
  default = [{
    name   = "Kompass"
    active = true
  }]
}

variable "trusted_principal" {
  description = "Trusted AWS principal allowed to assume the role"
  type        = string
  default     = "arn:aws:iam::672188301118:root"
}

variable "cur_s3_bucket" {
  description = "The s3 bucket suffix to export the cur report into"
  type        = string
  default     = "zesty-cur-bucket"
}

variable "cur_report_name" {
  description = "The cur report's name"
  type        = string
  default     = "ZestyCurReport"
}

variable "glue_db_name" {
  description = "The glue database name"
  type        = string
  default     = "zesty_cur"
}

variable "athena_workgroup" {
  description = "Athena workgroup"
  type        = string
  default     = "ZestyCur"
}

variable "values_yaml_filename" {
  description = "Path of values.yaml (default is the current working directory)"
  type        = string
  default     = "values.yaml"
}

variable "glue_crawler_name" {
  description = "The zesty crawler name"
  type = string
  default = "zesty_cur_glule_crawler"
}

variable "create_values_local_file" {
  description = "Enables the creation of a local values.yaml file"
  type        = bool
  default     = true
}
