#Providers
provider "aws" {
  access_key = ""
  secret_key = ""
  region     = "eu-west-1"
}

#VPC
module "vpc" {
  source = "github.com/terraform-community-modules/tf_aws_vpc"
  name = "techtest"
  cidr = "10.0.0.0/16"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_dns_hostnames = "true"
  enable_dns_support = "true"
  azs = ["eu-west-1a","eu-west-1b","eu-west-1c"]
}

#Security Group
    resource "aws_security_group" "nodes-sg" {
  name        = "test-nodes-sg"
  description = "Slave Nodes Security Group"
  vpc_id      = "${module.vpc.vpc_id}"

  tags {
    Name         = "test-nodes-sg"
    }
}

#Rules Out
resource "aws_security_group_rule" "nodes-sg-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.nodes-sg.id}"
}

#Rule IN
resource "aws_security_group_rule" "nodes-sg-allow-ssh"{
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.nodes-sg.id}"
}

#Rule IN - Port APP PROD
resource "aws_security_group_rule" "nodes-sg-allow-prod"{
  type              = "ingress"
  from_port         = 5000
  to_port           = 5000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.nodes-sg.id}"
}

#Rule IN - Port APP DEV
resource "aws_security_group_rule" "nodes-sg-allow-dev"{
  type              = "ingress"
  from_port         = 6000
  to_port           = 6000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.nodes-sg.id}"
}

#Create Machine
resource "aws_instance" "techtest" {
  ami                         = "ami-674cbc1e"
  instance_type               = "t2.micro"
  key_name                    = "fernando"
  vpc_security_group_ids      = ["${aws_security_group.nodes-sg.id}"]
  associate_public_ip_address = true

  tags {
    Name         = "techtest"
   }

  root_block_device {
    volume_type = "gp2"
    volume_size = "10"
  }

  user_data         = <<EOF
#cloud-config
write_files:
    - path: /etc/systemd/system/app-prod.service
      owner: root:root
      permissions: '0660'
      content: |
        [Unit]
        Description=Docker execution app prod
        Requires=docker.service
        After=docker.service

        [Service]
        User=root
        Restart=on-failure
        RestartSec=10
        Type=simple
        ExecStartPre=-/usr/bin/docker kill app-prod
        ExecStartPre=-/usr/bin/docker rm app-prod
        ExecStart=/bin/sh -c '/usr/bin/docker run --privileged --name app-prod -e ENV=production --net=host ffelicissimo/techtest:latest'
        ExecStop=-/usr/bin/docker stop app-prod

        [Install]
        WantedBy=multi-user.target
    - path: /etc/systemd/system/app-dev.service
      owner: root:root
      permissions: '0660'
      content: |
        [Unit]
        Description=Docker execution app dev
        Requires=docker.service
        After=docker.service

        [Service]
        User=root
        Restart=on-failure
        RestartSec=10
        Type=simple
        ExecStartPre=-/usr/bin/docker kill app-dev
        ExecStartPre=-/usr/bin/docker rm app-dev
        ExecStart=/bin/sh -c '/usr/bin/docker run --privileged --name app-dev -e ENV=development --net=host ffelicissimo/techtest:latest'
        ExecStop=-/usr/bin/docker stop app-dev

        [Install]
        WantedBy=multi-user.target
runcmd:
  - sleep 30
  - apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
  - apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main'
  - apt-get update
  - apt-get install -y docker-engine
  - systemctl restart systemd-journald
  - sleep 30
  - mkdir /etc/systemd/system/docker.service.wants/
  - ln -s /etc/systemd/system/app-prod.service /etc/systemd/system/docker.service.wants/
  - ln -s /etc/systemd/system/app-dev.service /etc/systemd/system/docker.service.wants/
  - systemctl daemon-reload
  - sleep 10
  - systemctl restart --no-block docker  
EOF
  availability_zone = "eu-west-1a"
  subnet_id         = "${element(module.vpc.public_subnets,0)}"
}
