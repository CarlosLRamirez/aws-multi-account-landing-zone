#Cross-account role for the workload app: MyWebApp-dev, where I deploy an app called BrewOps

data "aws_iam_policy_document" "brewops_state_reader_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::172644092356:root"]
    }
  }
}

resource "aws_iam_role" "brewops_state_reader" {
  name               = "brewops-terraform-state-reader"
  assume_role_policy = data.aws_iam_policy_document.brewops_state_reader_trust.json
  description        = "Read-only access to the landing zone Terraform state, for the BrewOps workload account"
}

data "aws_iam_policy_document" "brewops_state_reader_permissions" {
  statement {
    sid       = "ReadLandingZoneStateObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::mylz2027-terraform-state-189053741492/landing-zone/terraform.tfstate"]
  }

  statement {
    sid       = "ListOnlyThatPrefix"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::mylz2027-terraform-state-189053741492"]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["landing-zone/terraform.tfstate"]
    }
  }
}

resource "aws_iam_role_policy" "brewops_state_reader" {
  name   = "read-landing-zone-state"
  role   = aws_iam_role.brewops_state_reader.id
  policy = data.aws_iam_policy_document.brewops_state_reader_permissions.json
}
