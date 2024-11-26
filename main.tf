terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "DemoVPC" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "DemoVPC"
  }
}

resource "aws_subnet" "PublicSubnet1" {
  vpc_id = aws_vpc.DemoVPC.id
  cidr_block = "10.0.0.0/20"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "PublicSubnet1"
  }
}

resource "aws_subnet" "PublicSubnet2" {
  vpc_id = aws_vpc.DemoVPC.id
  cidr_block = "10.0.32.0/20"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "PublicSubnet2"
  }
}

resource "aws_subnet" "PrivateSubnet" {
  vpc_id = aws_vpc.DemoVPC.id
  cidr_block = "10.0.16.0/20"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "PrivateSubnet"
  }
}

resource "aws_internet_gateway" "igw_for_DemoVPC" {
  vpc_id = aws_vpc.DemoVPC.id

  tags = {
    Name = "igw_for_DemoVPC"
  }
}

resource "aws_route_table" "RouteTableForPublicSubnet1" {
  vpc_id = aws_vpc.DemoVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_for_DemoVPC.id
  }

  tags = {
    Name = "RouteTableForPublicSubnet1"
  }
}

resource "aws_route_table" "RouteTableForPublicSubnet2" {
  vpc_id = aws_vpc.DemoVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_for_DemoVPC.id
  }

  tags = {
    Name = "RouteTableForPublicSubnet2"
  }
}

resource "aws_route_table" "RouteTableForPrivateSubnet" {
  vpc_id = aws_vpc.DemoVPC.id

  tags = {
    Name = "RouteTableForPrivateSubnet"
  }
}

resource "aws_route_table_association" "associate_route_table_to_private_subnet" {
  subnet_id      = aws_subnet.PrivateSubnet.id
  route_table_id = aws_route_table.RouteTableForPrivateSubnet.id
}

resource "aws_route_table_association" "associate_route_table_to_public_subnet1" {
  subnet_id      = aws_subnet.PublicSubnet1.id
  route_table_id = aws_route_table.RouteTableForPublicSubnet1.id
}

resource "aws_route_table_association" "associate_route_table_to_public_subnet2" {
  subnet_id      = aws_subnet.PublicSubnet2.id
  route_table_id = aws_route_table.RouteTableForPublicSubnet2.id
}

resource "aws_security_group" "user-note-service-sg" {
  name        = "user-note-service-sg"
  description = "sg for user and note servers"
  vpc_id      = aws_vpc.DemoVPC.id

  tags = {
    Name = "for-user-note-service-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "for-user-note-service-allow-inbound-at-8080" {
  security_group_id = aws_security_group.user-note-service-sg.id
  referenced_security_group_id = aws_security_group.alb-sg.id
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

resource "aws_instance" "NoteService" {
  ami           = "ami-0dee22c13ea7a9a67"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.PrivateSubnet.id
  security_groups = [aws_security_group.user-note-service-sg.id]
  tags = {
    Name = "NoteService"
  }
}


resource "aws_instance" "UserService" {
  ami           = "ami-0dee22c13ea7a9a67"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.PrivateSubnet.id
  security_groups = [aws_security_group.user-note-service-sg.id]
  tags = {
    Name = "UserService"
  }
}

resource "aws_security_group" "zookeeper-sg" {
  name        = "zookeeper-sg"
  description = "sg for zookeeper server"
  vpc_id      = aws_vpc.DemoVPC.id

  tags = {
    Name = "zookeeper-sg"
  }
}

resource "aws_security_group" "kafka-sg" {
  name        = "kafka-sg"
  description = "sg for kafka server"
  vpc_id      = aws_vpc.DemoVPC.id

  tags = {
    Name = "kafka-sg"
  }
}


resource "aws_vpc_security_group_ingress_rule" "for-kafka-allow-inbound-at-9092" {
  security_group_id = aws_security_group.kafka-sg.id
  referenced_security_group_id = aws_security_group.user-note-service-sg.id
  from_port         = 9092
  ip_protocol       = "tcp"
  to_port           = 9092
}

resource "aws_vpc_security_group_ingress_rule" "for-zookeeper-allow-inbound-at-2181" {
  security_group_id = aws_security_group.zookeeper-sg.id
  referenced_security_group_id = aws_security_group.kafka-sg.id
  from_port         = 2181
  ip_protocol       = "tcp"
  to_port           = 2181
}


resource "aws_instance" "KafkaServer" {
  ami           = "ami-0dee22c13ea7a9a67"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.PrivateSubnet.id

  tags = {
    Name = "KafkaServer"
  }
}

resource "aws_instance" "ZookeeperServer" {
  ami           = "ami-0dee22c13ea7a9a67"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.PrivateSubnet.id

  tags = {
    Name = "ZookeeperServer"
  }
}

resource "aws_lb_target_group" "tg-userservice" {
  name     = "tg-userservice"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.DemoVPC.id
}

resource "aws_lb_target_group_attachment" "attachment-tg-userservice" {
  target_group_arn = aws_lb_target_group.tg-userservice.arn
  target_id        = aws_instance.UserService.id
  port             = 8080
}

resource "aws_lb_target_group" "tg-noteservice" {
  name     = "tg-noteservice"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.DemoVPC.id
}

resource "aws_lb_target_group_attachment" "attachment-tg-noteservice" {
  target_group_arn = aws_lb_target_group.tg-noteservice.arn
  target_id        = aws_instance.NoteService.id
  port             = 8080
}


resource "aws_security_group" "alb-sg" {
  name        = "alb-sg"
  description = "sg for alb"
  vpc_id      = aws_vpc.DemoVPC.id

  tags = {
    Name = "alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow-inbound-at-80" {
  security_group_id = aws_security_group.alb-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_lb" "alb-user-note-application" {
  name               = "alb-user-note-application"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = [aws_subnet.PublicSubnet1.id, aws_subnet.PublicSubnet2.id]

  enable_deletion_protection = false
}