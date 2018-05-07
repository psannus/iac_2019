resource "aws_security_group" "management" {
  name = "management"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "ec2-user" {
  key_name = "kowalski"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDLeXQX2CVdJnQk5TGtspVcqhM8ZuS/b8G9OqZe79tnADMmaWnoC2vgF9gkHBdEdCIl/Aa0jpPPF0oA0MaiooINa2aAl71Hdngs5pmn7Kk+OMq1rmfSo77f+b/MOATBLjnDLkHvEvRHmlNdYyA/cnU+rj6R4+VvGYA1wfLtdSqb8IBSr6flwGSlMFjPgHVIOOBy8Jb0oWhuG3p4+RD4cxjgLInpJa59Es9ecNabk8mQPId6wmNQxSsUVuhWUcOVVvqyJHTcfU8DbAwei8+7wpzQNiB5PEVn6rO1C5CJeXJZen2NM+CeZLKLsjRUqCsky3lnp17/rTRwjQ4j1+pZREzx+ZfHE4/ZFc1RH9T3X7bj/+TQseAuyhiGlxz/Txn0otlXzeIxkqBxfa3ZJj3Bs4xOP7bFSa67DCzMKuj7SQoupKzUYO2k7jeNAAto5R4Rfufspp/gE/mkPwt4DC9RrjHsFH9D/NgZW+1bn33FCCXW5YIrAPqyT/RjLiYxdSccwp7MoaYRiUHjpaf++lWutN/oACP9DYNjMSd7IvVKFqxfLtyjN7cF5fsqA24qomDRuB2gI7AfuZRzL9ZUL4cGlrLLkst1H5PmxrP5IjLgozH4QPY0MQGYwWON+qyloSdcCyCkIkAV3f7GPk4sA17N5gmNQoqisqnA9zdDm+bG/7Cz5w=="
}

resource "aws_instance" "myapp-server-1" {
  ami           = "ami-b144195a" // Amazon Linux 2 LTS Candidate 2 AMI
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.management.name}"]
  key_name = "${aws_key_pair.ec2-user.key_name}"

  provisioner "local-exec" {
    command = "echo ${aws_instance.myapp-server-1.public_ip} > ip_address.txt"
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "ec2-user"
      private_key = "${file("~/.ssh/id_rsa")}"
      agent = false
    }
    inline = [
      "sudo yum install -y java-1.8.0-openjdk"
    ]
  }
}
