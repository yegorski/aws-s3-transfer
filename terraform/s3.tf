module "s3_destination" {
  source = "git::https://github.com/yegorski/terraform-aws-s3-bucket.git?ref=master"

  name        = "BUCKET_NAME"
  description = "S3 destination to transfer other buckets. Managed with Terraform."

  tags = "${var.tags}"
}

resource "aws_s3_bucket_policy" "s3_destination" {
  bucket = "${module.s3_destination.id}"
  policy = "${data.aws_iam_policy_document.s3_destination.json}"
}

data "aws_iam_policy_document" "s3_destination" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:role/${module.ec2.iam_role_name}"]
    }

    actions = [
      "s3:*",
    ]

    resources = [
      "${module.s3_destination.arn}",
      "${module.s3_destination.arn}/*",
    ]
  }
}
