# ---------------------------------------------------------------
# Topologia de red
# ---------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project}-igw" }
}

resource "aws_subnet" "public" {
  for_each = var.subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = { Name = "${var.project}-${each.key}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "${var.project}-rt-publica" }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------
# Reglas de seguridad (definidas 100% en terraform.tfvars)
# ---------------------------------------------------------------
resource "aws_security_group" "web" {
  name        = "${var.project}-sg-web"
  description = "Reglas de seguridad para servidores web (GitOps)"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "${var.project}-sg-web" }
}

resource "aws_vpc_security_group_ingress_rule" "web" {
  for_each = var.web_ingress_rules

  security_group_id = aws_security_group.web.id
  description       = each.value.description
  ip_protocol       = each.value.protocol
  from_port         = each.value.port
  to_port           = each.value.port
  cidr_ipv4         = each.value.cidr

  tags = { Name = each.key }
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.web.id
  description       = "Salida a Internet (apt, etc.)"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ---------------------------------------------------------------
# Servidores
# ---------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "ansible" {
  key_name   = "${var.project}-ansible"
  public_key = var.ssh_public_key
}

locals {
  subnet_ids = [for k in sort(keys(aws_subnet.public)) : aws_subnet.public[k].id]
}

resource "aws_instance" "web" {
  count = var.web_count

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ansible.key_name
  vpc_security_group_ids = [aws_security_group.web.id]
  # reparte los servidores entre las subredes (alta disponibilidad basica)
  subnet_id = local.subnet_ids[count.index % length(local.subnet_ids)]

  tags = { Name = "${var.project}-web-${count.index + 1}", Role = "web" }
}
