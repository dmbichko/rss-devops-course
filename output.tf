
output "bastion_public_ip" {
  description = "Bastion Public IP"
  value       = aws_instance.ec2-k8s-bastion.public_ip
}

output "EC2_k3s-agent" {
  value       = aws_instance.ec2-k3s-worker.private_ip
  description = "K3S Agent IP Address"
}

output "EC2_k3s-server" {
  value = {
    private_ip = aws_instance.ec2-k3s_server.private_ip
  }
}

output "k3s_server_id" {
  value = aws_instance.k3s_server.id
}

output "bastion_server_id" {
  value       = aws_instance.ec2-k8s-bastion.id
  description = "Bastion Server ID"
}

