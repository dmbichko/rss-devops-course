
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


/*resource "time_sleep" "wait_for_k3s_server" {
  depends_on = [aws_instance.k3s_server]

  create_duration = "120s"
}*/


# Create a private key for aws instances
resource "aws_key_pair" "EC2-instance_key" {
  key_name = "K8s-EC2-ssh-key"
  # public_key = file("${path.module}/ec2-ssh-key.pub")
  # store pub key in github secter
  public_key = var.ec2-ssh-key
}

# Create a private key for bastion host
resource "aws_key_pair" "bastion_key" {
  key_name = "K8s-Bastion-ssh-key"
  # public_key = file("${path.module}/bastion-ssh-key.pub")
  # store pub key in github secter
  public_key = var.bastion-ssh-key
}

resource "aws_instance" "nat" {
  count         = length(aws_subnet.public_subnets[*].id)
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.ec2-instance-type
  key_name      = aws_key_pair.EC2-instance_key.key_name
  #subnet_id         = element(aws_subnet.public_subnets[*].id, count.index)

  network_interface {
    network_interface_id = aws_network_interface.nat_eni[count.index].id
    device_index         = 0
  }


  # Security group configuration allowing SSH access
  /*vpc_security_group_ids = [
    aws_security_group.nat_sg.id
  ]*/
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y iptables-services
              echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
              sysctl -p
              iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
              service iptables save
              systemctl enable iptables
              systemctl start iptables
              reboot
              EOF
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-ec2-k8s-nat-${count.index + 1}" })
  )
}


resource "aws_instance" "ec2-k8s-public" {
  count         = length(aws_subnet.public_subnets[*].id)
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2-instance-type
  key_name      = aws_key_pair.EC2-instance_key.key_name

  subnet_id = element(aws_subnet.public_subnets[*].id, count.index)

  # Security group configuration allowing SSH access
  vpc_security_group_ids = [
    aws_security_group.public_instances.id
  ]
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-ec2-k8s-public-${count.index + 1}" })
  )
}

resource "aws_instance" "ec2-k8s-private" {
  count         = length(aws_subnet.private_subnets[*].id)
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2-instance-type
  key_name      = aws_key_pair.EC2-instance_key.key_name

  subnet_id = element(aws_subnet.private_subnets[*].id, count.index)

  # Security group configuration allowing SSH access and icmp
  vpc_security_group_ids = [
    aws_security_group.allow_all_privata_sub.id
  ]

  user_data = <<-EOF
              #!/bin/bash
              #until nc -z ${aws_instance.k3s_server.private_ip} 6443; do
              #  echo "Waiting for K3s server to be ready..."
              #  sleep 5
              #done
              #curl -sfL https://get.k3s.io | \
              #K3S_URL=https://${aws_instance.k3s_server.private_ip}:6443 \
              #K3S_TOKEN=${var.k3s_token} \
              #sh -s - agent --kubelet-arg "node-labels=node-role.kubernetes.io/worker=worker"
              # Install K3s agent and register the worker node with the desired label
              curl -sfL https://get.k3s.io | \
              INSTALL_K3S_EXEC="agent --server https://${aws_instance.k3s_server.private_ip}:6443 --token ${var.k3s_token} --kubelet-arg 'node-labels=node-role.kubernetes.io/worker=worker'" \
              sh -s -
              EOF

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-ec2-k3s-agent-${count.index + 1}" })
  )
  depends_on    = aws_instance.k3s_server
}

resource "aws_instance" "ec2-k8s-bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2-instance-type
  key_name      = aws_key_pair.bastion_key.key_name

  subnet_id = aws_subnet.public_subnets[0].id

  # Security group configuration allowing SSH access
  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-ec2-k8s-bastion" })
  )
}

resource "aws_instance" "k3s_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2-instance-type
  key_name      = aws_key_pair.EC2-instance_key.key_name
  subnet_id     = aws_subnet.public_subnets[0].id

  #install k3s server
  vpc_security_group_ids = [
    aws_security_group.allow_all_privata_sub.id
  ]
  #!!!!!!!!!!!!!!!!! You should add special SG

  user_data = <<-EOF
              #!/bin/bash
              curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - --token ${var.k3s_token}
              EOF

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-k3s-server" })
  )
}



