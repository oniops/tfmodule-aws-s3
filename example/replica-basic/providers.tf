terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}

# Refers to environment variables [AWS_PROFILE, AWS_REGION].
provider "aws" {
  region = module.ctx.region
}

locals {
  replica_region = "ap-northeast-2"
}

provider "aws" {
  alias  = "replica"
  region = local.replica_region

  # Make it faster by skipping something
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  # skip_requesting_account_id  = true
}
