resource "aws_vpc" "dev-vpc" {
  cidr_block = "172.30.0.0/16"

  tags = {
    Name = "demo-vpc"
  }
}

resource "aws_internet_gateway" "demo-public-igw" {
  vpc_id = aws_vpc.dev-vpc.id

  tags = {
    Name = "demo-public-igw"
  }
}

resource "aws_subnet" "demo-public-subnet" {
  vpc_id     = aws_vpc.dev-vpc.id
  cidr_block = "172.30.1.0/24"

  availability_zone = "us-east-1c"

  tags = {
    Name = "demo-public-subnet"
  }
}

resource "aws_route_table" "demo-public-route-table" {
  vpc_id = aws_vpc.dev-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo-public-igw.id
  }

  tags = {
    Name = "demo-public-route-table"
  }
}

resource "aws_route_table_association" "demo-public-route_table_assoc" {
  route_table_id = aws_route_table.demo-public-route-table.id
  subnet_id      = aws_subnet.demo-public-subnet.id
}

resource "aws_route" "route-to-my-vpc" {
  route_table_id            = aws_route_table.demo-public-route-table.id
  destination_cidr_block    = aws_vpc.prod-vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.my-peering-connection.id
}

resource "aws_security_group" "demo-security-group-allow-ssh" {
  name        = "demo-allow-ssh"
  description = "Allow ssh connection from the main vpc"
  vpc_id      = aws_vpc.dev-vpc.id

  ingress {
    description     = "Allow ssh from instanced in production vpc"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.allow-http.id]
  }

  tags = {
    Name = "demo-security-group-allow-ssh"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow-access-to-internet" {
  security_group_id = aws_security_group.demo-security-group-allow-ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_key_pair" "demo-key-pair" {
  key_name   = "demo-key"
  public_key = file("${path.module}/demo-key.pub")
}

resource "aws_network_interface" "demo-network-interface" {
  subnet_id       = aws_subnet.demo-public-subnet.id
  security_groups = [aws_security_group.demo-security-group-allow-ssh.id]

  tags = {
    Name = "demo-network-interface"
  }
}

data "aws_ami" "amazon-linux-2" {
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


resource "aws_instance" "dev-instance" {
  ami           = data.aws_ami.amazon-linux-2.id
  instance_type = var.instance_type

  key_name = aws_key_pair.demo-key-pair.key_name
  network_interface {
    network_interface_id = aws_network_interface.demo-network-interface.id
    device_index         = 0
  }

  tags = {
    Name = "demo-instance"
  }
}