resource "aws_lambda_function" "url_shortener_POST" {
  filename         = "lambda_function.zip"  # Path to your Lambda deployment package
  function_name    = "URLShortenerLambda_POST"
  role             = aws_iam_role.lambda_exec_role.arn  # Role created above
  handler          = "lambda_function.lambda_handler_POST"  # Handler name from your code
  runtime          = "python3.10"  # Runtime for your Lambda function
  source_code_hash = filebase64sha256("lambda_function.zip")  # Hash for deployment package
}

resource "aws_lambda_function" "url_shortener_GET" {
  filename         = "lambda_function.zip"  # Path to your Lambda deployment package
  function_name    = "URLShortenerLambda_GET"
  role             = aws_iam_role.lambda_exec_role.arn  # Role created above
  handler          = "lambda_function.lambda_handler_GET"  # Handler name from your code
  runtime          = "python3.10"  # Runtime for your Lambda function
  source_code_hash = filebase64sha256("lambda_function.zip")  # Hash for deployment package
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_cloudwatch_logs" {
  name = "lambda_cloudwatch_logs_policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# DynamoDB access policy
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "lambda_dynamodb_policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ],
        Resource = "arn:aws:dynamodb:us-east-1:${data.aws_caller_identity.current.account_id}:table/ShortenedURLs"
      }
    ]
  })
}


resource "aws_lambda_permission" "apigw_invoke_POST" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.url_shortener_POST.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:us-east-1:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.url_shortener_api.id}/*/*/*"
}

resource "aws_lambda_permission" "apigw_invoke_GET" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.url_shortener_GET.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:us-east-1:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.url_shortener_api.id}/*/*/*"
}


data "aws_caller_identity" "current" {}
