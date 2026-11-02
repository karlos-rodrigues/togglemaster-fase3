output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}

output "subnets_publicas" {
  value = aws_subnet.publica[*].id
}

output "subnets_privadas" {
  value = aws_subnet.privada[*].id
}
