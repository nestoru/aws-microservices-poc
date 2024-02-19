resource "aws_vpc" "vpc1" {
  cidr_block           = "10.2.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc1"
  }
}
resource "aws_subnet" "subnet1_a" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = "10.2.1.0/24"
  availability_zone = "eu-north-1a"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "subnet1_a"
    "kubernetes.io/cluster/cluster1" = "shared"
    "kubernetes.io/role/elb"             = "1"
  }
}

resource "aws_subnet" "subnet1_b" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = "10.2.2.0/24"
  availability_zone = "eu-north-1b"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "subnet1_b"
    "kubernetes.io/cluster/cluster1" = "shared"
    "kubernetes.io/role/elb"             = "1"
  }
}

resource "aws_security_group" "sg1" {
  vpc_id = aws_vpc.vpc1.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg1"
  }
}

# Ensure Internet connectivity for the VPC
resource "aws_internet_gateway" "igw1" {
  vpc_id = aws_vpc.vpc1.id
  tags = {
    Name = "igw1"
  }
}

resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw1.id
  }

  tags = {
    Name = "rt1"
  }
}

resource "aws_route_table_association" "rt1_a" {
  subnet_id      = aws_subnet.subnet1_a.id
  route_table_id = aws_route_table.rt1.id
}

resource "aws_route_table_association" "rt1_b" {
  subnet_id      = aws_subnet.subnet1_b.id
  route_table_id = aws_route_table.rt1.id
}

resource "aws_acm_certificate" "cert1" {
  domain_name       = "test2.nestorurquiza.com"
  validation_method = "DNS"

  tags = {
    Name = "cert1"
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "existing" {
  name         = "nestorurquiza.com."
  private_zone = false
}

resource "aws_route53_record" "test_cert_validation" {
  for_each = {
    for dvo in tolist(aws_acm_certificate.cert1.domain_validation_options) : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      value  = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.existing.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60
}
