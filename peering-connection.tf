resource "aws_vpc_peering_connection" "my-peering-connection" {
  vpc_id      = aws_vpc.prod-vpc.id
  peer_vpc_id = aws_vpc.dev-vpc.id
  auto_accept = true

  #   accepter {
  #     allow_remote_vpc_dns_resolution = true
  #   }
  #   requester {
  #     allow_remote_vpc_dns_resolution = true
  #   }

  #   tags = {
  #     Name = "VPC peering between my two vpc's"
  #   }
}