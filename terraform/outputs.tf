output "private_ip" {
  value = "${module.ec2.private_ip}"
}

output "bucket_name" {
  value = "${module.s3_destination.id}"
}
