resource "aws_key_pair" "key" {
  key_name   = "${var.app_name}"
  public_key = "${var.public_key}"
}

module "ec2" {
  source = "git::https://github.com/yegorski/terraform-aws-ec2.git?ref=master"

  name        = "${var.app_name}"
  size        = "t3.micro"        # 2 CPU, 1 GB memory
  volume_size = "20"

  aws_account_id    = "${var.aws_account_id}"
  ami_lookup_filter = "Amazon Linux 2*"

  vpc_id            = "${var.vpc_id}"
  subnet_id         = "${var.subnet_ids[0]}"
  security_group_id = "${aws_security_group.ec2.id}"
  region            = "${var.region}"

  associate_public_ip_address = false

  ssh_ip = "${var.ssh_ip}"

  ssh_key_name = "${aws_key_pair.key.key_name}"

  tags = "${var.tags}"
}

resource "aws_iam_policy" "allow_bucket_full_access" {
  name        = "s3-migration-allow-full-access"
  path        = "/"
  description = ""

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3BucketGlacierAllowFullAccess",
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "${module.s3_destination.arn}",
        "BUCKET_A_ARN",
        "BUCKET_B_ARN"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "allow_bucket_full_access" {
  role       = "${module.ec2.iam_role_name}"
  policy_arn = "${aws_iam_policy.allow_bucket_full_access.arn}"
}
