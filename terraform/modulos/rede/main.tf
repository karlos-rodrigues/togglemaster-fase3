locals {
  tags = merge(var.tags, { Projeto = "togglemaster", GerenciadoPor = "terraform" })
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.tags, { Name = "${var.nome}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.nome}-igw" })
}

resource "aws_subnet" "publica" {
  count                   = length(var.cidrs_publicas)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.cidrs_publicas[count.index]
  availability_zone       = var.zonas[count.index]
  map_public_ip_on_launch = !var.nat_gateway
  tags = merge(local.tags, {
    Name                                = "${var.nome}-publica-${var.zonas[count.index]}"
    "kubernetes.io/role/elb"            = "1"
    "kubernetes.io/cluster/${var.nome}" = "shared"
  })
}

resource "aws_subnet" "privada" {
  count             = length(var.cidrs_privadas)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.cidrs_privadas[count.index]
  availability_zone = var.zonas[count.index]
  tags = merge(local.tags, {
    Name                                = "${var.nome}-privada-${var.zonas[count.index]}"
    "kubernetes.io/role/internal-elb"   = "1"
    "kubernetes.io/cluster/${var.nome}" = "shared"
  })
}

resource "aws_eip" "nat" {
  count  = var.nat_gateway ? 1 : 0
  domain = "vpc"
  tags   = merge(local.tags, { Name = "${var.nome}-nat" })
}

resource "aws_nat_gateway" "this" {
  count         = var.nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.publica[0].id
  tags          = merge(local.tags, { Name = "${var.nome}-nat" })
  depends_on    = [aws_internet_gateway.this]
}

resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.nome}-rt-publica" })
}

resource "aws_route" "publica_internet" {
  route_table_id         = aws_route_table.publica.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "publica" {
  count          = length(aws_subnet.publica)
  subnet_id      = aws_subnet.publica[count.index].id
  route_table_id = aws_route_table.publica.id
}

resource "aws_route_table" "privada" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.nome}-rt-privada" })
}

resource "aws_route" "privada_nat" {
  count                  = var.nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.privada.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "privada" {
  count          = length(aws_subnet.privada)
  subnet_id      = aws_subnet.privada[count.index].id
  route_table_id = aws_route_table.privada.id
}
