
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
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2-instance-type
  key_name      = aws_key_pair.EC2-instance_key.key_name
  #source_dest_check = false
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
                sudo apt-get update
                sudo apt-get install iptables-services -y
                sudo systemctl enable iptables
                sudo systemctl start iptables

                # Turning on IP Forwarding
                sudo touch /etc/sysctl.d/custom-ip-forwarding.conf
                sudo chmod 666 /etc/sysctl.d/custom-ip-forwarding.conf
                sudo echo "net.ipv4.ip_forward=1" >> /etc/sysctl.d/custom-ip-forwarding.conf
                sudo sysctl -p /etc/sysctl.d/custom-ip-forwarding.conf

                # Making a catchall rule for routing and masking the private IP
                sudo /sbin/iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
                sudo /sbin/iptables -F FORWARD
                sudo service iptables save
                sudo service iptables restart
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

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-ec2-k8s-private-${count.index + 1}" })
  )
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

