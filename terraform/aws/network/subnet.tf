// ---------- [ Global Subnet ] -------------------------------
resource "aws_subnet" "global_a" {
  cidr_block              = "10.0.0.0/20"
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name : "global-a"
  }
}

resource "aws_subnet" "global_c" {
  cidr_block              = "10.0.16.0/20"
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "ap-northeast-1c"

  tags = {
    Name : "global-c"
  }
}

// ---------- [ Private Subnet ] -------------------------------
resource "aws_subnet" "private_a" {
  cidr_block              = "10.0.128.0/20"
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name : "private-a"
  }
}

resource "aws_subnet" "private_c" {
  cidr_block              = "10.0.144.0/20"
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "ap-northeast-1c"

  tags = {
    Name : "private-c"
  }
}
