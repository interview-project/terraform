terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# Configure the AWS Provider
provider "aws" {
  access_key = "${var.AWS_ACCESS_KEY_ID}"
  secret_key = "${var.AWS_SECRET_ACCESS_KEY}"
  region     = "us-east-1"
}

resource "aws_security_group" "provisioning_example-lb" {
    name = "provisioning_example lb"
    description = "Security group for the load balancer"
    ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["98.226.72.162/32", "204.14.236.213/32"]
    }
    ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["98.226.72.162/32"]
    }
    ingress {
      from_port = 8081
      to_port = 8081
      protocol = "tcp"
      cidr_blocks = ["98.226.72.162/32", "204.14.236.213/32"]
    }
    ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["98.226.72.162/32", "204.14.236.213/32"]
    }

    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
}
/* Our root SSH key pair is created by the wrapper script. */

resource "aws_key_pair" "root" {
    key_name = "root-key"
    public_key = "${file("id_rsa.pub")}"
}

# Create a Nexus Server
resource "aws_instance" "nexus" {
  ami           = "${var.nexus_ami}"
  instance_type = "t2.medium"
  key_name = "${aws_key_pair.root.key_name}"
  vpc_security_group_ids = ["${aws_security_group.provisioning_example-lb.id}"]
  tags {
    Name = "nexus.dev.local"
  }
}

resource "null_resource" "configure_nexus" {
  connection {
    host = "${aws_instance.nexus.public_ip}"
  }
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      agent       = false
      user        = "ubuntu"
      private_key = "${file("id_rsa")}"
    }
    inline = [
      "sudo docker run -d -p 8081:8081 --name nexus sonatype/nexus3",
    ]
  }
}

# Create a Jenkins master
resource "aws_instance" "jenkins" {
  ami           = "${var.jenkins_ami}"
  instance_type = "t2.medium"
  key_name = "${aws_key_pair.root.key_name}"
  vpc_security_group_ids = ["${aws_security_group.provisioning_example-lb.id}"]
  tags {
    Name = "jenkins.dev.local"
  }
}

# Create templates
data "template_file" "jenkins_location" {
  template = "${file("${path.module}/jenkins_configs/configure_jenkins_url.groovy.tpl")}"

  vars {
    jenkins_ip = "${aws_instance.jenkins.public_ip}"
  }
}
resource "null_resource" "configure_jenkins" {
  connection {
    host = "${aws_instance.jenkins.public_ip}"
  }
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      agent       = false
      user        = "ubuntu"
      private_key = "${file("id_rsa")}"
    }
    inline = [
      "sudo sh -c 'cat > /var/lib/jenkins/init.groovy.d/configure_jenkins_url.groovy << EOF \n${data.template_file.jenkins_location.rendered}\nEOF\n'",
      "sudo service jenkins restart"
    ]
  }
}
