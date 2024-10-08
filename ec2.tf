
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
  key_name   = "K8s-EC2-ssh-key"
  public_key = file("${path.module}/ec2-rss-school.pub")
  # store pub key in github secter
  #public_key = ec2_public_key
}

resource "aws_instance" "ec2-k8s" {
  count         = length(aws_subnet.public_subnets[*].id)
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2-instance-type
  key_name      = aws_key_pair.instance_key.EC2-instance_key

  subnet_id = element(aws_subnet.public_subnets[*].id, count.index)

  # Security group configuration allowing SSH access
  security_groups = ["${aws_security_group.allow_ssh.id}"]

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-EC2-K8s-${count.index + 1}" })
  )
}

output "EC2_instance_details" {
  value = [
    for instance in aws_instance.ec2-k8s : {
      instance_id = instance.id
      public_ip   = instance.public_ip
      private_ip  = instance.private_ip
      subnet_id   = instance.subnet_id
    }
  ]
}

output "EC2_instance_public_ip" {
  value = aws_instance.ec2-k8s[*].public_ip
}

