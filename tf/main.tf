terraform {
  required_version = "= 0.11.7"
}

provider "aws" {
  version = "~> 1.17"
  region = "eu-central-1"

  allowed_account_ids = [
    "743872050755",
  ]
}
