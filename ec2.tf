
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

data "template_file" "user_data" {
  template = file("${path.module}/nginx_proxy_userdata.sh")

  vars = {
    jenkins_private_ip = aws_instance.ec2-k3s_server.private_ip
    jenkins_nodeport   = "32000"
  }
}

# Create a private key for aws instances
resource "aws_key_pair" "EC2-instance_key" {
  key_name = "K8s-EC2-ssh-key"
  #public_key = file("${path.module}/ec2-ssh-key.pub")
  # store pub key in github secter
  public_key = var.ec2-ssh-key
}

# Create a private key for bastion host
resource "aws_key_pair" "bastion_key" {
  key_name = "K8s-Bastion-ssh-key"
  #public_key = file("${path.module}/bastion-ssh-key.pub")
  # store pub key in github secter
  public_key = var.bastion-ssh-key
}

resource "aws_instance" "nat" {
  count         = length(aws_subnet.public_subnets[*].id)
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.ec2-instance-type
  key_name      = aws_key_pair.EC2-instance_key.key_name

  network_interface {
    network_interface_id = aws_network_interface.nat_eni[count.index].id
    device_index         = 0
  }

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

resource "aws_instance" "ec2-k8s-bastion" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.ec2-instance-type
  key_name             = aws_key_pair.bastion_key.key_name
  iam_instance_profile = aws_iam_instance_profile.bastion_profile.name

  subnet_id = aws_subnet.public_subnets[0].id

  # Security group configuration allowing SSH access
  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-ec2-k8s-bastion" })
  )
}

resource "aws_instance" "ec2-k3s_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2-instance-type-k3s
  #instance_type        = var.ec2-instance-type
  key_name  = aws_key_pair.EC2-instance_key.key_name
  subnet_id = aws_subnet.private_subnets[0].id

  #install k3s server
  vpc_security_group_ids = [
    aws_security_group.allow_all_privata_sub.id
  ]
  #!!!!!!!!!!!!!!!!! You should add special SG

  user_data  = <<-EOF
              #!/bin/bash
              curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - --token ${var.k3s_token}
              chmod 644 /etc/rancher/k3s/k3s.yaml
              cp /etc/rancher/k3s/k3s.yaml /home/system.administrator/.kube/conf
              chown system.administrator:system.administrator /home/system.administrator/.kube/conf
              EOF
  depends_on = [aws_instance.nat]
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-ec2-k3s-server" })
  )
}
/*!!!!
resource "aws_instance" "ec2-k3s-worker" {
  count         = length(aws_subnet.private_subnets[*].id)
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2-instance-type
  key_name      = aws_key_pair.EC2-instance_key.key_name
  subnet_id     = element(aws_subnet.private_subnets[*].id, count.index)

  # Security group configuration allowing SSH access and icmp
  vpc_security_group_ids = [
    aws_security_group.allow_all_privata_sub.id
  ]

  user_data = <<-EOF
              #!/bin/bash
              until nc -z ${aws_instance.ec2-k3s_server.private_ip} 6443; do
                echo "Waiting for K3s server to be ready..."
                sleep 5
              done
              # Install K3s agent and register the worker node with the desired label
              #curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.ec2-k3s_server.private_ip}:6443 K3S_TOKEN=${var.k3s_token} sh -s - agent --kubelet-arg="node-labels=node-role.kubernetes.io/worker=worker"
              curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.ec2-k3s_server.private_ip}:6443 K3S_TOKEN=${var.k3s_token} sh -s - agent
              EOF

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-ec2-k3s-agent" })
  )
  depends_on = [aws_instance.ec2-k3s_server]
}*/

/*!!!!
resource "aws_instance" "ec2-nginx-proxy" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2-instance-type
  key_name      = aws_key_pair.EC2-instance_key.key_name
  subnet_id     = aws_subnet.public_subnets[0].id
  ####change rules to have access to private network K3s
  vpc_security_group_ids = [
    aws_security_group.public_instances.id
  ]
  user_data = data.template_file.user_data.rendered
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-ec2-nginx-proxy" })
  )
  depends_on = [aws_instance.ec2-k3s_server]
}*/

resource "null_resource" "install_helm_jenkins" {
  depends_on = [aws_instance.ec2-k8s-bastion, aws_instance.ec2-k3s_server]
  triggers = {
    always_run = "${timestamp()}" # This will cause it to run on every apply
  }
  provisioner "local-exec" {
    command = <<EOF
    aws ssm send-command \
      --instance-ids ${aws_instance.ec2-k8s-bastion.id} \
      --document-name "AWS-RunShellScript" \
      --parameters '{
        "commands": [
          "# Update and install necessary packages",
          "sudo apt-get update",
          "sudo apt-get install -y unzip curl",
          "# Install AWS CLI",
          "curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o \"awscliv2.zip\"",
          "unzip awscliv2.zip",
          "sudo ./aws/install",
          "# Verify AWS CLI installation",
          "/usr/local/bin/aws --version",
          "# Install Helm",
          "curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash",
          "helm repo add jenkins https://charts.jenkins.io",
          "helm repo update",
          "# Install kubectl",
          "curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\"",
          "sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl",
          "kubectl version --client",
          "# Debug: Print current user and home directory",
          "echo \"Current user: $(whoami)\"",
          "echo \"Home directory: $HOME\"",
          "# Setup SSH key",
          "sudo mkdir -p /home/ubuntu/.ssh",
          "sudo /usr/local/bin/aws ssm get-parameter --name /ec2/keypair/K8s-EC2-ssh-key --with-decryption --query Parameter.Value --output text | sudo tee /home/ubuntu/.ssh/id_rsa > /dev/null",
          "sudo chmod 600 /home/ubuntu/.ssh/id_rsa",
          "sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa",
          "sudo mkdir /home/ubuntu/.kube/",
          "# Debug: Print SSH key info",
          "ls -l /home/ubuntu/.ssh/id_rsa",
          "# Copy k3s config",
          "sudo -u ubuntu ssh-keyscan -H ${aws_instance.ec2-k3s_server.private_ip} >> /home/ubuntu/.ssh/known_hosts",
          "sudo -u ubuntu scp -o StrictHostKeyChecking=no -i /home/ubuntu/.ssh/id_rsa ubuntu@${aws_instance.ec2-k3s_server.private_ip}:/etc/rancher/k3s/k3s.yaml /home/system.administrator/.kube/config",
          "if [ $? -eq 0 ]; then",
          "  sudo sed -i \"s/127.0.0.1/${aws_instance.ec2-k3s_server.private_ip}/g\" /home/system.administrator/.kube/config",
          "  echo \"K3s config successfully copied and modified\"",
          "else",
          "  echo \"Failed to copy K3s config\"",
          "  echo \"Debugging information:\"",
          "  sudo cat /home/ubuntu/.ssh/id_rsa | sed 's/.*/./'",
          "fi",
          "sudo chown ubuntu:ubuntu /home/system.administrator/.kube/config",
          "# Test kubectl",
          "kubectl get nodes",
          "kubectl get pods"
        ]
      }' \
      --output text
    EOF
  }
}




//Deleted these intances because of TAKS3
/*resource "aws_instance" "ec2-k8s-public" {
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

  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name
  subnet_id            = element(aws_subnet.private_subnets[*].id, count.index)

  # Security group configuration allowing SSH access and icmp
  vpc_security_group_ids = [
    aws_security_group.allow_all_privata_sub.id
  ]

  user_data = <<-EOF
              #!/bin/bash
              until nc -z ${aws_instance.k3s_server.private_ip} 6443; do
                echo "Waiting for K3s server to be ready..."
                sleep 5
              done
              # Install K3s agent and register the worker node with the desired label
              #curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.k3s_server.private_ip}:6443 K3S_TOKEN=${var.k3s_token} sh -s - agent --kubelet-arg="node-labels=node-role.kubernetes.io/worker=worker"
              curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.k3s_server.private_ip}:6443 K3S_TOKEN=${var.k3s_token} sh -s - agent
              EOF

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-ec2-k3s-agent-${count.index + 1}" })
  )
  depends_on = [aws_instance.k3s_server]
}*/