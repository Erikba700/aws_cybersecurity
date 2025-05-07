resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role"
assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "ecs_task_execution_role_attachment" {
  name       = "ecs-task-execution-role-policy-attachment"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  roles      = [aws_iam_role.ecs_execution_role.name]
}

resource "aws_ecs_task_definition" "demo_task" {
  family                = "test-family"
  execution_role_arn    = aws_iam_role.ecs_execution_role.arn
  task_role_arn         = aws_iam_role.ecs_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu    = "256"
  memory = "512"

  container_definitions = jsonencode([
    {
      name      = "demo-name-attribute"
      image     = "324037302117.dkr.ecr.us-east-1.amazonaws.com/dev-backend-images:demo-fix"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_ecs_cluster" "demo_cluster" {
  name = "demo-cluster"
}

resource "aws_ecs_service" "django_service" {
  name = "django-service"
  cluster         = aws_ecs_cluster.demo_cluster.id
  task_definition = aws_ecs_task_definition.demo_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.core_public[0].id]
    security_groups = [aws_security_group.ecs_task_sg.id]
    assign_public_ip = true
  }
}


resource "aws_security_group" "ecs_task_sg" {
  name        = "ecs-task-sg"
  description = "Allow HTTP/HTTPS traffic to ECS task"
  vpc_id = aws_vpc.core.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow inbound HTTP traffic from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

