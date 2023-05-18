terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.67.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "project" {
  type    = string
  default = "demo"
}

variable "environment" {
  type    = string
  default = "dev"
}

# Configure the AWS provider
provider "aws" {
  region = var.aws_region
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../lambda/main.py"
  output_path = "../lambda/main.zip"
}

resource "aws_lambda_function" "my_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project}_${var.environment}_my_lambda"
  role             = aws_iam_role.my_lambda_role.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = "data.archive_file.lambda_zip.output_base64sha256"
}

# Create an IAM role for Lambda
resource "aws_iam_role" "my_lambda_role" {
  name               = "my_lambda_role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com" 
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
  POLICY
}

# Create a custom IAM policy
resource "aws_iam_policy" "read_sqs_queue_policy" {
  name        = "my_lambda_role_policy"
  description = "Policy for my_lambda"
  policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "sqs:ReceiveMessage",
              "sqs:DeleteMessage",
              "sqs:GetQueueAttributes"
          ],
          "Resource": "*"
      }
  ]
}
  POLICY
}

# Attach one or more managed policies to the role
resource "aws_iam_role_policy_attachment" "role_policy_attachment_managed" {
  role = aws_iam_role.my_lambda_role.name
  for_each = toset([
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ])
  policy_arn = each.value
}

# Attach a custom policy to the role
resource "aws_iam_role_policy_attachment" "role_policy_attachment_custom" {
  role       = aws_iam_role.my_lambda_role.name
  policy_arn = aws_iam_policy.read_sqs_queue_policy.arn
}

resource "aws_sqs_queue" "my_queue" {
  name             = "my-queue"
  delay_seconds    = 30
  max_message_size = 262144
}

resource "aws_sqs_queue" "my_deadletter_queue" {
  name             = "my-deadletter-queue"
  delay_seconds    = 30
  max_message_size = 262144
}

resource "aws_lambda_event_source_mapping" "my-sqs-my-lambda-trigger" {
  event_source_arn = aws_sqs_queue.my_queue.arn
  function_name    = aws_lambda_function.my_lambda.arn
}

