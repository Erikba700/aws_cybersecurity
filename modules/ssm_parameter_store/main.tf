resource "aws_ssm_parameter" "my_parameter" {
  name        = "/${var.project}/${var.name}"
  description = var.description
  type        = var.type
  value       = var.value
  tags        = var.tags
}
