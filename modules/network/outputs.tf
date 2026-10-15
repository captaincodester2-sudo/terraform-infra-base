output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main_vpc.id
}

output "private_subnet_ids" {
  description = "Lista de los IDs de las subnets privadas"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}