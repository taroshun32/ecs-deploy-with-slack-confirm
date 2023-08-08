resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name : "igw"
  }
}

resource "aws_eip" "eip" {}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.global_a.id

  tags = {
    Name : "ngw"
  }
}
