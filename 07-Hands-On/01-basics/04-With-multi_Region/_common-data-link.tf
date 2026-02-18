data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.aws_region}"
  common_tags = merge(
    var.default_tags,
    {
      Owner      = var.owner
      AccountId = data.aws_caller_identity.current.account_id
    }
  )
}