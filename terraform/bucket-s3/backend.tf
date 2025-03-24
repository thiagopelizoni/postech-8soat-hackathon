terraform {
  backend "s3" {
    bucket  = "fcl-terraform-state"
    key     = "TechChallenge/bucket-s3/videos.gazetapress.com/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
