variable "aws_region" {
  type = map(any)
  default = {
    default = "us-east-1"
    prod    = "ap-southeast-1"
  }
}

variable "deployment_name" {
  type = map(any)
  default = {
    default = "mypython_dev"
    prod    = "mypython"
  }
}
