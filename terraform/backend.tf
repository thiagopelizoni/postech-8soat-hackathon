terraform {
  backend "s3" {
    bucket  = "fcl-terraform-state"
    key     = "TechChallenge/auth-service/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
