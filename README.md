# AWS VPC Project Documentation (Terraform)
Overview
This project sets up two VPCs on AWS using Terraform: a production VPC (prod-vpc) with public and private subnets, and a development VPC (dev-vpc). Instances in the private subnet access the internet through a NAT gateway in the public subnet. VPC peering enables communication between instances in both VPCs, leveraging the AWS backbone to reduce costs.
