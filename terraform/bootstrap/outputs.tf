# Prints the bucket name after `apply`, so it can be copied into the main
# project's backend block (terraform/main.tf, Step 2) without retyping it.
output "state_bucket_name" {
  description = "S3 bucket holding Terraform remote state for the rest of the landing zone."
  value       = aws_s3_bucket.terraform_state.bucket
}
