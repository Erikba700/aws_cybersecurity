resource "aws_key_pair" "core_instance_access" {
  key_name   = "${terraform.workspace}_core_instance_access"
  public_key = file("${path.module}/pub_keys/${terraform.workspace}_core_instance_access.pub")
  tags = {
    Name = "${terraform.workspace}_core_instance_access"
  }
}
