# module "network_secret_ro" {
#   source    = "../modules/sm-reader"
#   secret_id = "dev/core-network-secrets"
# }

module "ssm_parameter_core_az_count" {
  source  = "../modules/ssm_parameter_store"
  project = var.project_name
  name    = "core_az_count"
  type    = "String"
  value   = "2"
  tags = {
    Environment = "${terraform.workspace}-core_az_count"
    Project     = var.project_name
  }
}

module "ssm_parameter_core_vpc_cidr" {
  source  = "../modules/ssm_parameter_store"
  project = var.project_name
  name    = "core_vpc_cidr"
  type    = "String"
  value   = "10.0.0.0/16"
  tags = {
    Environment = "${terraform.workspace}-core_vpc_cidr"
    Project     = var.project_name
  }
}

data "aws_ssm_parameter" "core_az_count_parameter" {
  name = "/${var.project_name}/core_az_count" # Replace with the correct SSM parameter name
}

data "aws_ssm_parameter" "core_vpc_cidr_parameter" {
  name = "/${var.project_name}/core_vpc_cidr" # Replace with the correct SSM parameter name
}

output "ssm_parameter_core_az_count_output" {
  value = module.ssm_parameter_core_az_count.parameter_name_output
}
output "ssm_parameter_core_vpc_cidr_output" {
  value = module.ssm_parameter_core_vpc_cidr.parameter_name_output
}

data "aws_region" "current" {}


locals {
  az_suffix    = ["a", "b", "c", "d", "e", "f"]
  project_name = var.project_name

  # Core Component Configurations.
  core_name_prefix = "${terraform.workspace}.core"
  core_az_count    = data.aws_ssm_parameter.core_az_count_parameter.value
  core_vpc_cidr    = data.aws_ssm_parameter.core_vpc_cidr_parameter.value
  core_region      = data.aws_region.current.name
}
