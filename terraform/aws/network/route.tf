// ---------- [ Global Route Table ] -------------------------------
resource "aws_route_table" "global" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name : "global"
  }
}

resource "aws_route_table_association" "global_a" {
  route_table_id = aws_route_table.global.id
  subnet_id      = aws_subnet.global_a.id
}

resource "aws_route_table_association" "global_c" {
  route_table_id = aws_route_table.global.id
  subnet_id      = aws_subnet.global_c.id
}

// ---------- [ Private Route Table ] -------------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name : "private"
  }
}

resource "aws_route_table_association" "private_a" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private_a.id
}

resource "aws_route_table_association" "private_c" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private_c.id
}
