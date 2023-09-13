# Store the terraform state file in s3 and lock with dunamodb
terraform {
  backend "s3" {
    bucket         = "nodeapp-terraform-remote-state"
    key            = "terraform-module/rentzone/terraform.tfstate"
    region         = "eu-central-1"
    profile        = "intern"
    dynamodb_table = "terraform-state-lock"
  }
}