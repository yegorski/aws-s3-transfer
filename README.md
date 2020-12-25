# AWS S3 Transfer

Terraform and script to transfer multiple S3 buckets into a single destination bucket. This can be used for consolidating buckets to another AWS account as well.

The Terraform creates a server that is used transfer data and the destination S3 bucket inself.

Data migration is performed using AWS S3 CLI `sync` command.

To perform the sync the server has an IAM role attached that allows access to the buckets.

## Create a Destination Bucket and Server

To run a large migration, it may not be feasible to do it your local computer. You may need a (small) EC2 server.

> NOTE: Terraform steps below use the [AWS EC2 Instance][] and [AWS S3 Bucket][] Terraform modules.

1. Replace `BUCKET_NAME` in `terraform/s3.tf` with desired bucket name.
1. Update `aws_iam_policy` in `terraform/ec2.tf` with the bucket ARNs you want to transfer.
1. Replace `DESTINATOIN_BUCKET` in `s3.bash` with the same bucket name.
1. `cd terraform` and run `terraform apply` to create the bucket and the server.
1. Manually on each source bucket apply this bucket policy replacing `AWS_ACCOUNT_ID`, `BUCKET_NAME`, and `ROLE_NAME`, allowing the EC2's role to access the bucket:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "TransferDataFullBucketAccess",
         "Effect": "Allow",
         "Principal": {
           "AWS": "arn:aws:iam::AWS_ACCOUNT_ID:role/ROLE_NAME"
         },
         "Action": "s3:*",
         "Resource": ["arn:aws:s3:::BUCKET_NAME/*", "arn:aws:s3:::BUCKET_NAME"]
       }
     ]
   }
   ```

## Transfer Data

1. SSH into the server `ssh ec2-user@SERVER_ID`.
1. Become root `sudo su -`.
1. Check that the server has access to each bucket `aws s3 ls s3://BUCKET_NAME/`.
1. Copy the `s3.bash` file to the server and allow execution `chmod +x s3.bash`.
1. Update `source_buckets.txt` with the names of the buckets you want to transfer.
1. Place the file next to the bash script.
1. Invoke the `backup_all_buckets` bash function. Pass in the name of the text file, containing the source buckets. For example:

   ```bash
   nohup ./s3.bash backup_all_buckets source_buckets.txt &
   ```

1. The command execution is detached from the terminal session (via `nohup`) and are run in the backgroup (via trailing `&`). That way an SSH session timeout won't halt the migration.
1. The script will read in the buckets listed in the file and sync them to the destination bucket. Each synced file will have the source bucket name as the S3 prefix.
1. The script outputs a log file per bucket. Tail the log file to see progress: `tail -f SOURCE_BUCKET_NAME.log`.

## Teardown

After the migration, the server is longer needed.

1. So that you don't delete the S3 bucket when tearing down the server, remove the bucket from Terraform state:

   ```bash
   terraform state rm module.s3_destination.aws_s3_bucket.s3
   terraform state rm aws_s3_bucket_policy.s3_destination
   ```

1. Run `terraform destroy`.

[aws ec2 instance]: https://github.com/yegorski/terraform-aws-ec2
[aws s3 bucket]: https://github.com/yegorski/terraform-aws-s3-bucket
