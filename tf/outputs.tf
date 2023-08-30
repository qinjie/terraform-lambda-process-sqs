output "lambda_function_arn" {
  value = aws_lambda_function.mypython_lambda.arn
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.main_queue.arn
}

output "sqs_dlq_arn" {
  value = aws_sqs_queue.deadletter_queue.arn
}
