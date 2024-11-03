resource "aws_instance" "management" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.ec2-instance-type
  subnet_id            = aws_subnet.public_subnets[0].id
  key_name             = aws_key_pair.EC2-instance_key.key_name
  iam_instance_profile = aws_iam_instance_profile.management_profile.name

  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]

  user_data = <<-EOF
              #!/bin/bash
              # Exit on any error
              set -e

              # Function for error handling
              handle_error() {
                echo "Error occurred on line $1"
                exit 1
              }
              trap 'handle_error $LINENO' ERR

              # Install required packages
              sudo apt-get update
              sudo apt-get install -y unzip curl netcat-openbsd

              # Install AWS CLI
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              sudo ./aws/install
              rm -rf aws awscliv2.zip  # Cleanup

              # Install kubectl
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
              rm kubectl  # Cleanup

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
              
              echo "Waiting 2 minutes for k3s server to initialize..."
              sleep 90  # Initial wait for k3s server setup
              # Get kubeconfig from S3
              mkdir -p /home/ubuntu/.kube
              max_attempts=5
              attempt=1
              while [ $attempt -le $max_attempts ]; do
                if aws s3 cp s3://${aws_s3_bucket.k3s_config.id}/k3s.yaml /home/ubuntu/.kube/config; then
                  echo "Successfully downloaded kubeconfig"
                  break
                fi
                echo "Attempt $attempt failed, waiting before retry..."
                sleep 30
                attempt=$((attempt + 1))
              done

              if [ $attempt -gt $max_attempts ]; then
                echo "Failed to download kubeconfig after $max_attempts attempts"
                exit 1
              fi

              chmod 600 /home/ubuntu/.kube/config
              chown -R ubuntu:ubuntu /home/ubuntu/.kube

              # Create a directory for your files
              mkdir -p /opt/k3s-install-jenkins
              chown -R ubuntu:ubuntu /opt/k3s-install-jenkins

              # Switch to ubuntu user and execute remaining commands
              su - ubuntu << 'USEREOF'
              export KUBECONFIG=/home/ubuntu/.kube/config

              # Verify kubectl access
              if ! kubectl get nodes; then
                echo "Failed to access kubernetes cluster"
                exit 1
              fi
              cd /opt/k3s-install-jenkins

              # Clone your repository
              git clone -b task4 https://github.com/dmbichko/rss-devops-course.git

              # Navigate to the specific folder containing k3s files
              cd rss-devops-course/jenkins

              # Make your scripts executable
              chmod +x install-jenkins.sh
              # Execute your Jenkins installation script
              ./install-jenkins.sh
              USEREOF
              EOF

  tags = {
    Name = "${var.prefix}-management-k3s"
  }
  depends_on = [aws_instance.ec2-k3s_server]
}


