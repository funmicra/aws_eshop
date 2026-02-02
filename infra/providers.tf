provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "candle-shop"
      region     = var.aws_region
      profile    = var.aws_profile
      ManagedBy   = "Terraform"
    }
  }
}
