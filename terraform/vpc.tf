# VPC Satrted 

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Blazeclan-MSteam1"
  }
}

# VPC END

# IGW start
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw"
  }
}

#IGW End

#Subnet start

resource "aws_subnet" "Blazeclan-MSteam1-private-1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/19"
  availability_zone = "ap-south-1a"

  tags = {
    "Name"                                 = "Blazeclan-MSteam1-private-1a"
    "kubernetes.io/role/internal-elb"      = "1"
    "kubernetes.io/cluster/tf-eks-cluster" = "owned"
    "Terraform"                              = "true"
    "Environment"                            = "dev"
  }
}

resource "aws_subnet" "Blazeclan-MSteam1-private-1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.32.0/19"
  availability_zone = "ap-south-1b"

  tags = {
    "Name"                                 = "Blazeclan-MSteam1-private-1b"
    "kubernetes.io/role/internal-elb"      = "1"
    "kubernetes.io/cluster/tf-eks-cluster" = "owned"
    "Terraform"                              = "true"
    "Environment"                            = "dev"
  }
}

resource "aws_subnet" "Blazeclan-MSteam1-public-1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.64.0/19"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    "Name"                                 = "Blazeclan-MSteam1-public-1a"
    "kubernetes.io/role/elb"               = "1"
    "kubernetes.io/cluster/tf-eks-cluster" = "owned"
    "Terraform"                              = "true"
    "Environment"                            = "dev"
  }
}

resource "aws_subnet" "Blazeclan-MSteam1-public-1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.96.0/19"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    "Name"                                 = "Blazeclan-MSteam1-public-1b"
    "kubernetes.io/role/elb"               = "1"
    "kubernetes.io/cluster/tf-eks-cluster" = "owned"
    "Terraform"                              = "true"
    "Environment"                            = "dev"
  }
}

#Subnet END


#Nat gateway 

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "nat"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.Blazeclan-MSteam1-public-1a.id

  tags = {
    Name = "nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

#Nat gateway End

#route table 

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "private-ap-south-1a" {
  subnet_id      = aws_subnet.Blazeclan-MSteam1-private-1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private-ap-south-1b" {
  subnet_id      = aws_subnet.Blazeclan-MSteam1-private-1b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public-ap-south-1a" {
  subnet_id      = aws_subnet.Blazeclan-MSteam1-public-1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-ap-south-1b" {
  subnet_id      = aws_subnet.Blazeclan-MSteam1-public-1b.id
  route_table_id = aws_route_table.public.id
}
