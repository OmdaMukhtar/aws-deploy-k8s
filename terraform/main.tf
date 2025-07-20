provider "aws" {
  region = var.aws_region
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "id_rsa"
  public_key = file("~/.ssh/id_rsa.pub")
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"] # Canonical Official

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_security_group" "k8s" {
  name   = "k8s-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # testing and execute commands on api server.
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
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

resource "aws_instance" "master" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = data.aws_subnets.default.ids[0]
  security_groups = [aws_security_group.k8s.id]

  iam_instance_profile = aws_iam_instance_profile.master_ssm_profile.name

  user_data = templatefile("${path.module}/scripts/master.sh.tpl", {
    pod_network_cidr = "10.244.0.0/16"
    aws_region = var.aws_region
  })

  tags = {
    Name = "k8s-master"
  }
}

data "aws_ssm_parameter" "join_command" {
  name = "/k8s/join-command"
  depends_on = [null_resource.lamp_deploy]
}

resource "aws_instance" "worker" {
  count         = 2
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = data.aws_subnets.default.ids[0]
  security_groups = [aws_security_group.k8s.id]

  
  user_data = templatefile("${path.module}/scripts/worker.sh.tpl", {
    master_private_ip = aws_instance.master.private_ip
    kubeadm_join_command = data.aws_ssm_parameter.join_command.value
  })

  tags = {
    Name = "k8s-worker-${count.index}"
  }
}




resource "null_resource" "lamp_deploy" {
  depends_on = [aws_instance.master]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = aws_instance.master.public_ip
  }

  provisioner "file" {
    source      = "../kubernetes"
    destination = "/home/ubuntu/kubernetes/"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/lamp-deploy.sh.tpl"
    destination = "/home/ubuntu/lamp-deploy.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/lamp-deploy.sh",
      "bash /home/ubuntu/lamp-deploy.sh"
    ]
  }
}
