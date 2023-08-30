
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../lambda"
  output_path = "main.zip"
}

resource "aws_lambda_function" "mypython_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.deployment_name[terraform.workspace]}_lambda_test"
  role             = aws_iam_role.mypython_lambda_role.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

resource "aws_iam_role" "mypython_lambda_role" {
  name               = "${var.deployment_name[terraform.workspace]}_role_test"
  assume_role_policy = <<EOF
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
  EOF
}

data "aws_iam_policy_document" "mypython_lambda_role_policy_doc" {
  statement {
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [
      aws_sqs_queue.main_queue.arn,
    ]
  }
}

resource "aws_iam_policy" "mypython_lambda_role_policy" {
  name   = "${var.deployment_name[terraform.workspace]}_lambda_role_policy"
  policy = data.aws_iam_policy_document.mypython_lambda_role_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "mypython_lambda_policy_attachment" {
  role       = aws_iam_role.mypython_lambda_role.name
  policy_arn = aws_iam_policy.mypython_lambda_role_policy.arn
}

resource "aws_sqs_queue" "main_queue" {
  name             = "${var.deployment_name[terraform.workspace]}-main-queue"
  delay_seconds    = 30
  max_message_size = 2048
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.deadletter_queue.arn
    maxReceiveCount     = 4
  })
}

resource "aws_sqs_queue" "deadletter_queue" {
  name             = "${var.deployment_name[terraform.workspace]}-deadletter-queue"
  delay_seconds    = 30
  max_message_size = 2048
}

resource "aws_lambda_event_source_mapping" "sqs-lambda-trigger" {
  event_source_arn = aws_sqs_queue.main_queue.arn
  function_name    = aws_lambda_function.mypython_lambda.arn
}

