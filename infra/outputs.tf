
# Output the VPC ID
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.core.id
}

# Output the private subnet IDs
output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.core_private[*].id
}

# output "vpc_cidr" {
#   description = "The CIDR block of the VPC"
#   value       = aws_vpc.core.cidr_block
# }

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.core_public[*].id
}

# You might also want to output the availability zones used
output "availability_zones" {
  description = "List of availability zones used"
  value       = aws_subnet.core_private[*].availability_zone
}


output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.core_public.id
}

output "private_route_table_ids" {
  description = "The IDs of the private route tables"
  value       = aws_route_table.core_private[*].id
}
