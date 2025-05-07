resource "aws_ecr_repository" "backend-images" {
  name                 = "${terraform.workspace}-backend-images"
  image_tag_mutability = "MUTABLE"
  force_delete         = true


  image_scanning_configuration {
    scan_on_push = true
  }
}