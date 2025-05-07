provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Env       = terraform.workspace
      ManagedBy = "terraform"
      Project   = local.project_name
    }
  }
}