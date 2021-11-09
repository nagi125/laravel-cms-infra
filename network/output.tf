output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.publics.*.id
}

output "private_subnet_ids" {
  value = aws_subnet.privates.*.id
}

output "ec2_subnet_id" {
  value = aws_subnet.ec2.id
}
