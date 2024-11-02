resource "aws_instance" "management" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.ec2-instance-type
  subnet_id            = var.public_subnets[0].id
  key_name             = aws_key_pair.EC2-instance_key.key_name
  iam_instance_profile = aws_iam_instance_profile.management_profile.name

  vpc_security_group_ids = [aws_security_group.management.id]

  user_data = <<-EOF
              #!/bin/bash
              # Install required packages
              sudo apt-get update
              sudo apt-get install -y unzip curl netcat-openbsd

              # Install AWS CLI
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install

              # Install kubectl
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

              # Install Helm
              curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

              # Set up SSH config for proxy
              mkdir -p /home/ubuntu/.ssh
              cat <<'SSHCONFIG' > /home/ubuntu/.ssh/config
              Host bastion
                HostName ${aws_instance.ec2-k8s-bastion.public_ip}
                User ubuntu
                IdentityFile ~/.ssh/bastion-key
                StrictHostKeyChecking no

              Host k3s-server
                HostName ${aws_instance.ec2-k3s_server.private_ip}
                User ubuntu
                IdentityFile ~/.ssh/ec2-key
                ProxyCommand ssh -W %h:%p bastion
                StrictHostKeyChecking no
              SSHCONFIG

              # Get SSH keys from SSM Parameter Store
              aws ssm get-parameter --name /ec2/keypair/K8s-Bastion-ssh-key --with-decryption --query Parameter.Value --output text > /home/ubuntu/.ssh/bastion-key
              aws ssm get-parameter --name /ec2/keypair/K8s-EC2-ssh-key --with-decryption --query Parameter.Value --output text > /home/ubuntu/.ssh/ec2-key
              chmod 600 /home/ubuntu/.ssh/bastion-key /home/ubuntu/.ssh/ec2-key
              chown -R ubuntu:ubuntu /home/ubuntu/.ssh

              # Set up proxy script
              cat <<'PROXYSCRIPT' > /home/ubuntu/setup-proxy.sh
              #!/bin/bash
              ssh -f -N -D 1080 bastion
              export https_proxy=socks5://localhost:1080
              PROXYSCRIPT

              chmod +x /home/ubuntu/setup-proxy.sh
              chown ubuntu:ubuntu /home/ubuntu/setup-proxy.sh

              # Get kubeconfig from S3
              mkdir -p /home/ubuntu/.kube
              aws s3 cp s3://${aws_s3_bucket.k3s_config.id}/k3s.yaml /home/ubuntu/.kube/config
              chmod 600 /home/ubuntu/.kube/config
              chown -R ubuntu:ubuntu /home/ubuntu/.kube

              kubectl get pods
              EOF

  tags = {
    Name = "${var.prefix}-management"
  }
  depends_on = [aws_instance.ec2-k3s_server]
}

# Output the instance ID for use in the Jenkins deployment pipeline
output "management_instance_id" {
  value = aws_instance.management.public_ip
}
