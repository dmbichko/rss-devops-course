# Elastic IP for Bastion
resource "aws_eip" "bastion" {
  instance = aws_instance.ec2-k8s-bastion.id
  domain   = "vpc"
}

output "bastion_public_ip" {
  value = aws_eip.bastion.public_ip
}

output "EC2_public_instance_details" {
  value = [
    for instance in aws_instance.ec2-k8s-public : {
      instance_id = instance.id
      public_ip   = instance.public_ip
      private_ip  = instance.private_ip
      subnet_id   = instance.subnet_id
    }
  ]
}

output "EC2_private_instance_details" {
  value = [
    for instance in aws_instance.ec2-k8s-private : {
      instance_id = instance.id
      public_ip   = instance.public_ip
      private_ip  = instance.private_ip
      subnet_id   = instance.subnet_id
    }
  ]
}

output "k3s-server" {
  value = [
    for instance in aws_instance.k3s_server : {
      public_ip  = instance.public_ip
      private_ip = instance.private_ip
    }
  ]
}
