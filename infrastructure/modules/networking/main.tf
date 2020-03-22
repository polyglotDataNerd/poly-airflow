/*
  vpc
*/

resource "aws_vpc" vpc {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-${var.environment}"
    Enviorment = var.environment
  }
}

/*
  EIPS
*/
resource "aws_eip" natgwEIP {
  vpc = true
  tags = {
    Name = "natGWeip-${var.environment}"
    Enviorment = var.environment
    Description = "elastic IP tied to NAT Gateway"
  }
}

resource "aws_eip" bastionEIP {
  vpc = true
  tags = {
    Name = "bastionEIP-${var.environment}"
    Enviorment = var.environment
    Description = "elastic IP tied to the bastion proxy"
  }
}


/*
  Subnets
*/
resource "aws_internet_gateway" "bd-igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "bd-igw-${var.environment}"
    Environment = var.environment
  }
}

# Define the NAT gateway
resource "aws_nat_gateway" "bd-NAT" {

  #EIP association
  allocation_id = aws_eip.natgwEIP.id

  subnet_id = element(aws_subnet.public-subnet.*.id, 0)
  depends_on = [
    aws_internet_gateway.bd-igw]
  tags = {
    Name = "bd-NAT-${var.environment}"
    Environment = var.environment
  }
}

/* Public subnet */
resource "aws_subnet" "public-subnet" {
  vpc_id = aws_vpc.vpc.id
  count = length(split(",", var.public_subnets[var.environment]))
  cidr_block = element(split(",", var.public_subnets[var.environment]), count.index)
  availability_zone = element(var.availability_zone, count.index)

  tags = {
    Name = "${element(var.availability_zone, count.index)}-public-subnet-${var.environment}"
    Environment = var.environment
  }

}


/* Private subnet */
resource "aws_subnet" "private-subnet" {
  vpc_id = aws_vpc.vpc.id
  count = length(split(",", var.private_subnets[var.environment]))
  cidr_block = element(split(",", var.private_subnets[var.environment]), count.index)
  availability_zone = element(var.availability_zone, count.index)

  tags = {
    Name = "${element(var.availability_zone, count.index)}-private-subnet-${var.environment}"
    Environment = var.environment
  }

}


#Define Route Tables and Associate to Subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "private-route-table-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "public-route-table-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_route" "public-rt-igw" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.bd-igw.id
}

resource "aws_route" "private-rt-nat" {
  route_table_id = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.bd-NAT.id
}

/* Route table associations */
resource "aws_route_table_association" "public" {
  count = length(split(",", var.public_subnets[var.environment] ))
  subnet_id = element(aws_subnet.public-subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(split(",", var.private_subnets[var.environment] ))
  subnet_id = element(aws_subnet.private-subnet.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

/*====
VPC's Default Security Group
======*/
# default
resource "aws_security_group" "bd-security-group" {
  name = "bd-security-group-${var.environment}"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id = aws_vpc.vpc.id
  depends_on = [
    aws_vpc.vpc]

  #ssh with bastion hosts Elastic IP's
  ingress {
    from_port = "22"
    to_port = "22"
    protocol = "TCP"
    self = true
    cidr_blocks = [
      "${aws_eip.bastionEIP.public_ip}/32"]
    description = "Bastion SSH"
  }


  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    self = "true"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
    Name = "bd-security-group-${var.environment}"
  }
}

# bastion
resource "aws_security_group" "bd-security-group-bastion" {
  name = "bd-bastion-${var.environment}"
  description = "Bastion security group"
  vpc_id = aws_vpc.vpc.id
  depends_on = [
    aws_vpc.vpc]

  #ssh with bastion hosts Elastic IP's
  ingress {
    from_port = "22"
    to_port = "22"
    protocol = "TCP"
    self = true
    cidr_blocks = [
      "0.0.0.0/0"]
    description = "Unrestricted ingress specifically just for Bastion Host"
  }


  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    self = "true"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
    Name = "bd-bastion-${var.environment}"
  }
}

# databases sg
resource "aws_security_group" "bd-security-group-dbs" {
  name = "bd-security-group-dbs-${var.environment}"
  description = "security group to allow database access"
  vpc_id = aws_vpc.vpc.id
  depends_on = [
    aws_vpc.vpc]

  #ssh with bastion hosts Elastic IP's
  ingress {
    from_port = "22"
    to_port = "22"
    protocol = "TCP"
    self = true
    cidr_blocks = [
      "${aws_eip.bastionEIP.public_ip}/32"]
    description = "Bastion SSH"
  }

  #redshift
  ingress {
    from_port = "5439"
    to_port = "5439"
    protocol = "TCP"
    self = true
  }

  #postgres
  ingress {
    from_port = "5432"
    to_port = "5432"
    protocol = "TCP"
    self = true
  }

  #mysql
  ingress {
    from_port = "3306"
    to_port = "3306"
    protocol = "TCP"
    self = true
  }

  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    self = "true"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
    Name = "bd-security-group-dbs-${var.environment}"
  }
}

#elb
# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "bd-security-group-elb" {
  name = "bd-security-group-elb-${var.environment}"
  description = "Security group for public facing ELBs"
  vpc_id = aws_vpc.vpc.id

  # HTTP access from anywhere
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  # HTTPS access from anywhere
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  #HUE
  ingress {
    from_port = "8888"
    to_port = "8888"
    protocol = "TCP"
    self = true
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  #ZEPPELIN
  ingress {
    from_port = "8890"
    to_port = "8890"
    protocol = "TCP"
    self = true
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  # Outbound internet access
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
    Name = "bd-security-group-elb-${var.environment}"
  }
}


/*====
RSA Key for our bastion host
resource "aws_key_pair" "bastion_key" {
  key_name = "bastion-${var.environment}"
  public_key = "${var.proxy}"
}
======*/


/*====
s3 vpc endpoints provide a secure connection to S3 that does not require a gateway or NAT instances.
======*/
resource "aws_vpc_endpoint" "s3-vpc-ep" {
  service_name = "com.amazonaws.us-west-2.s3"
  vpc_id = aws_vpc.vpc.id
  tags = {
    Environment = var.environment
    Name = "s3-endpoint-${var.environment}"
  }
}

resource "aws_vpc_endpoint_route_table_association" "s3-vpc-ep-assoc" {
  route_table_id = aws_route_table.private.id
  vpc_endpoint_id = aws_vpc_endpoint.s3-vpc-ep.id
}

resource "aws_vpc_endpoint" "apiGW-vpc-ep" {
  service_name = "com.amazonaws.us-west-2.execute-api"
  vpc_id = aws_vpc.vpc.id
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.bd-security-group.id,
    aws_security_group.bd-security-group-dbs.id]
  //  subnet_ids = [
  //    split(",", var.private_subnets[var.environment])]
  tags = {
    Environment = var.environment
    Name = "execute-api-endpoint-${var.environment}"
  }
}

/*====
Bastion Proxy Server
https://bhargavamin.com/tech-article/difference-between-bastion-host-and-nat-instance-aws/
======*/
resource "aws_instance" "bastion" {
  ami = "ami-0ce21b51cb31a48b8"
  key_name = "bastion-${var.environment}"
  iam_instance_profile = "admin"
  instance_type = "t2.nano"
  security_groups = [
    aws_security_group.bd-security-group-bastion.id]
  subnet_id = element(aws_subnet.public-subnet.*.id, 3)
  associate_public_ip_address = true
  tags = {
    Environment = var.environment
    Name = "bigdata-bastion-${var.environment}"
  }
}

/*util box
resource "aws_instance" "bigdata-util" {
  ami = "ami-0d6246b09a6c66c08"
  key_name = "bigdata-proxy"
  iam_instance_profile = "bigdata-dev-role"
  instance_type = "m5.large"
  security_groups = [
    "${aws_security_group.bd-security-group.id}",
    "${aws_security_group.bd-security-group-dbs.id}"]
  subnet_id = "${element(aws_subnet.private-subnet.*.id, 3)}"
  tags = {
    Environment = "${var.environment}"
    Name = "bigdata-util-${var.environment}"
  }
}*/


resource "aws_eip_association" "eip_assoc" {
  instance_id = aws_instance.bastion.id
  allocation_id = aws_eip.bastionEIP.id
  allow_reassociation = true
}


/*====
VPC's Default Security Group
Creates elastic load balancer for production EMR HUE and Zepplin with HTTPS
https://simonfredsted.com/1459
======
resource "aws_elb" "elb-emr" {
  name = "bd-elb-emr-${var.environment}"

  security_groups = [
    "${aws_security_group.bd-security-group-elb.id}",
    "${aws_security_group.bd-security-group.id}"]
  subnets = ["${aws_subnet.public-subnet.*.id}"]

  access_logs {
    bucket = "bigdata-utility"
    bucket_prefix = "elb/447388672287/${var.environment}"
    interval = 60
    enabled = true
  }

  listener {
    instance_port = 8000
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  listener {
    instance_port = 8000
    instance_protocol = "http"
    lb_port = 443
    lb_protocol = "https"
    ssl_certificate_id = "${var.ssl_cert_query}"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:8000/"
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags ={
    Environment = "${var.environment}"
    Name = "bd-elb-emr-${var.environment}"
  }
}*/