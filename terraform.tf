variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "pub_key" {}

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "us-east-1"
}

# RDS Resource
resource "aws_db_instance" "buildtree" {
    identifier = "buildtree-rds"
    allocated_storage = 10
    engine = "postgresql"
    engine_version = "9.4.4"
    instance_class = "db.t2.micro"
    name = "buildtree_production"
    username = "buildtree_proudction"
    password = "xyzpasswordgoeshere"
# backups?
}

resource "aws_db_security_group" "default" {
    name = "rds_sg"
    description = "RDS default security group"

    ingress {
        security_group_name = "${aws_security_group.ssh.name}"
    }
}

# Change the name of this resource
resource "aws_instance" "service" {
  ami = "ami-1146f77a"
  instance_type = "m1.small"
  key_name = "${aws_key_pair.deployer.key_name}"
  security_groups = ["${aws_security_group.web.name}","${aws_security_group.ssh.name}"]

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "ubuntu"
      agent = true
    }
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade",
      "sudo curl -sSL https://get.docker.com/ | sh",
      "sudo docker pull pcorliss/buildtree",
    ]
  }
}

resource "aws_instance" "workers" {
  ami = "ami-1146f77a"
  count = 2
  instance_type = "m1.small"
  key_name = "${aws_key_pair.deployer.key_name}"
  security_groups = ["${aws_security_group.ssh.name}"]

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "ubuntu"
      agent = true
    }
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade",
      "sudo curl -sSL https://get.docker.com/ | sh",
      "sudo docker pull pcorliss/buildtree",
    ]
  }
}

resource "aws_key_pair" "deployer" {
  key_name = "buildtree-deployer-key"
  public_key = "${var.pub_key}"
}

resource "aws_security_group" "ssh" {
  name = "allow_ssh"
  description = "Allow all inbound ssh traffic, and all outbound traffic"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web" {
  name = "allow_web"
  description = "Allow all inbound http traffic"

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}
