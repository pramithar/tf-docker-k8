
 #internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
          Name = var.project_name
          Terraform = "true"
          Environment = "DEV"
         }
}

#VPC
resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  instance_tenancy = var.instance_tenancy
  enable_dns_support = var.dns_support
  enable_dns_hostnames = var.dns_hostnames
         tags = var.tags
}

#security group for postgress RDS, 5432
resource "aws_security_group" "allow_postgress" {
  name        = "allow_postgress"
  description = "Allow postgress inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "TLS from VPC"
    from_port        = var.postgress_port
    to_port          = var.postgress_port
    protocol         = "tcp"
    cidr_blocks      = var.cidr_list
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = var.tags
}

#public subnet

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
          Name = "${var.project_name}-public-subnet"
          Terraform = "true"
          Environment = "DEV"
        }
}

resource "aws_route_table" "pulic_route_table" {
  vpc_id = aws_vpc.main.id

  route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
       }
    

    tags = {
          Name = "${var.project_name}-public-routetable"
          Terraform = "true"
          Environment = "DEV"
        }

}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.pulic_route_table.id
}

#private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.11.0/24"

  tags = {
          Name = "${var.project_name}-private-subnet"
          Terraform = "true"
          Environment = "DEV"
        }
}

 resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id

    tags = {
          Name = "${var.project_name}-private-routetable"
          Terraform = "true"
          Environment = "DEV"
        }

}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}
 
 #database subnet
 resource "aws_subnet" "database_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.21.0/24"

  tags = {
          Name = "${var.project_name}-database-subnet"
          Terraform = "true"
          Environment = "DEV"
        }
}
resource "aws_route_table" "database_route_table" {
  vpc_id = aws_vpc.main.id

    tags = {
          Name = "${var.project_name}-database-routetable"
          Terraform = "true"
          Environment = "DEV"
        }

}

resource "aws_route_table_association" "database" {
  subnet_id      = aws_subnet.database_subnet.id
  route_table_id = aws_route_table.database_route_table.id
}

resource "aws_eip" "nat"{
  domain = "vpc"
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.public_subnet.id
  
}

 resource "aws_route" "private" {
  route_table_id = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.ngw.id
  #depends on = [aws_route_table.private]

} 

resource "aws_route" "database" {
  route_table_id = aws_route_table.database_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.ngw.id
  #depends on = [aws_route_table.private]
} 


 # using count to create 3 instances
resource "aws_instance" "web-server" {
  count = 3
  ami = "ami-0b9ecf71fe947bbdd"
  instance_type = "t2.micro"
  tags = {
    Name = var.instance_names[count.index]
  }
  
} 

resource "aws_instance" "condition" {
  ami = "ami-0b9ecf71fe947bbdd"
  instance_type = var.isProd ? "t3.large" : "t2.micro"
}