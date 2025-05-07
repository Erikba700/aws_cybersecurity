data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/20.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

resource "aws_instance" "public_instance" {
  ami           = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type = "t2.nano"
  key_name      = aws_key_pair.core_instance_access.key_name
  subnet_id     = aws_subnet.core_public[0].id
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "${terraform.workspace}-public-ec2"
  }
}

resource "aws_instance" "private_instance" {
  ami           = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type = "t2.nano"
  key_name      = aws_key_pair.core_instance_access.key_name
  subnet_id     = aws_subnet.core_private[0].id
  associate_public_ip_address = true # I'm adding this intentionally

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "${terraform.workspace}-private-ec2"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.core.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${terraform.workspace}-allow-ssh"
  }
}


