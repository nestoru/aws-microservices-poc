output "vpc1_id" {
  value = aws_vpc.vpc1.id
}

output "subnet1_ids" {
  value = [aws_subnet.subnet1_a.id, aws_subnet.subnet1_b.id]
}

output "sg1_id" {
  value = aws_security_group.sg1.id
}

output "cert1_arn" {
  value = aws_acm_certificate.cert1.arn
}

