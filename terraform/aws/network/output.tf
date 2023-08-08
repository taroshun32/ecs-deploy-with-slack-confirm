output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "subnet_public_a_id" {
  value = aws_subnet.global_a.id
}

output "subnet_public_c_id" {
  value = aws_subnet.global_c.id
}

output "subnet_private_a_id" {
  value = aws_subnet.private_a.id
}

output "subnet_private_c_id" {
  value = aws_subnet.private_c.id
}
