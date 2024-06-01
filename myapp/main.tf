provider "aws" {
  region = "us-east-1"
}

# יצירת VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# יצירת Subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# יצירת Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# יצירת Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# יצירת Route Table Association
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# יצירת Security Group
resource "aws_security_group" "allow_http" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# יצירת EC2 instance ל-Flask
resource "aws_instance" "flask_instance" {
  ami           = "ami-0c55b159cbfafe1f0"  # Ubuntu 20.04 LTS
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.main.id
  security_groups = [aws_security_group.allow_http.name]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y python3 python3-pip
              pip3 install flask pymongo
              sudo apt-get install -y nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
              echo "server {
                    listen 80;
                    server_name your_domain;
                    location / {
                        proxy_pass http://localhost:5000;
                        proxy_set_header Host \$host;
                        proxy_set_header X-Real-IP \$remote_addr;
                        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                        proxy_set_header X-Forwarded-Proto \$scheme;
                    }
                }" | sudo tee /etc/nginx/sites-available/default
              sudo systemctl restart nginx
              EOF

  tags = {
    Name = "FlaskInstance"
  }
}

# יצירת EC2 instance ל-MongoDB
resource "aws_instance" "mongodb_instance" {
  ami           = "ami-0c55b159cbfafe1f0"  # Ubuntu 20.04 LTS
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.main.id
  security_groups = [aws_security_group.allow_http.name]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y mongodb
              sudo systemctl start mongod
              sudo systemctl enable mongod
              EOF

  tags = {
    Name = "MongoDBInstance"
  }
}

# יצירת רשומת A ב-Route 53
resource "aws_route53_record" "www" {
  zone_id = "your_zone_id" # הכנס את ה-Zone ID שלך כאן
  name    = "your_domain"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.flask_instance.public_ip]
}

# יצירת ELB (רשות - אם תרצה לאזן בין מספר אינסטנסים)
resource "aws_elb" "web" {
  name               = "flask-app-elb"
  availability_zones = ["us-east-1a"]

  listener {
    instance_port     = 5000
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  instances = [aws_instance.flask_instance.id]

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
