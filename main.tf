provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "my-vpc-igw"
  }
}

resource "aws_subnet" "public-subnet" {
  vpc_id            = aws_vpc.my-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "route-table-assoc" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet.id
}

resource "aws_key_pair" "my-key" {
  key_name   = "my-key"
  public_key = file("${path.module}/my-key.pub")
}

resource "aws_security_group" "allow-http" {
  name        = "allow-http"
  description = "Allow httpd from everywhere"
  vpc_id      = aws_vpc.my-vpc.id

  tags = {
    Name = "allow-http"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress-rule" {
  security_group_id = aws_security_group.allow-http.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "allow-ssh" {
  security_group_id = aws_security_group.allow-http.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "allow-http" {
  security_group_id = aws_security_group.allow-http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_network_interface" "pubic-network-interface" {
  security_groups = [aws_security_group.allow-http.id]
  subnet_id       = aws_subnet.public-subnet.id

  tags = {
    Name = "pubic-network-interface"
  }
}

data "aws_ami" "amazon-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }

}

resource "aws_instance" "my-server" {
  ami           = data.aws_ami.amazon-linux.id
  instance_type = var.instance_type

  key_name = aws_key_pair.my-key.key_name

  network_interface {
    network_interface_id = aws_network_interface.pubic-network-interface.id
    device_index         = 0
  }

  user_data = filebase64("scripts/user_data.sh")

  tags = {
    Name = "my-server"
  }
}

resource "aws_eip" "name" {
  network_interface = aws_network_interface.pubic-network-interface.id
  depends_on = [aws_instance.my-server]
}






















