output "parameter_name_output" {
  description = "The name of the created SSM parameter."
  value       = "Name: ${aws_ssm_parameter.my_parameter.name}}"
}