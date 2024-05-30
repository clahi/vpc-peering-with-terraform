variable "aws_region" {
  description = "The region of our infrastructure"
  default     = "us-east-1"
}

variable "instance_type" {
  default = "t3.micro"
}