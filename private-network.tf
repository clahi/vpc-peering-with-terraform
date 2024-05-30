resource "aws_subnet" "private-subnet" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_security_group" "allow-access-to-internet" {
  name        = "allow-access"
  description = "Allow instances in private network access to the internet"
  vpc_id      = aws_vpc.prod-vpc.id

  tags = {
    Name = "allow-acces-to-internet"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow-ssh-private-subnet" {
  security_group_id = aws_security_group.allow-access-to-internet.id
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "10.0.1.0/24"
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow-access" {
  security_group_id = aws_security_group.allow-access-to-internet.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_network_interface" "private-network-interface" {
  subnet_id       = aws_subnet.private-subnet.id
  security_groups = [aws_security_group.allow-access-to-internet.id]

  tags = {
    Name = "private-network-interface"
  }
}

resource "aws_route_table" "private-subnet-route-table" {
  vpc_id = aws_vpc.prod-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gateway.id
  }

  tags = {
    Name = "private-subnet-route-table"
  }
}

resource "aws_route_table_association" "private-subnet-assoc" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-subnet-route-table.id
}

resource "aws_eip" "for-nat-gateway" {
}

resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.for-nat-gateway.id
  subnet_id     = aws_subnet.public-subnet.id

  tags = {
    Name = "gw NAT"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_instance" "private-server" {
  ami           = data.aws_ami.amazon-linux.id
  instance_type = var.instance_type

  key_name = "private-key"
  network_interface {
    network_interface_id = aws_network_interface.private-network-interface.id
    device_index         = 0
  }

  tags = {
    Name = "private-server"
  }
}