data "template_file" "user_data" {
  template = file("${path.module}/nginx_proxy_userdata.sh")

  vars = {
    jenkins_private_ip = aws_instance.ec2-k3s_server.private_ip
    jenkins_nodeport   = var.jenkins_nodeport
    wordpress_private_ip = aws_instance.ec2-k3s_server.private_ip
    wordpress_nodeport   = var.wordpress_nodeport
  }
}

resource "aws_instance" "ec2-nginx-proxy" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2-instance-type
  key_name      = aws_key_pair.EC2-instance_key.key_name
  subnet_id     = aws_subnet.public_subnets[0].id

  vpc_security_group_ids = [
    aws_security_group.public_instances.id
  ]
  user_data = data.template_file.user_data.rendered
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-ec2-nginx-proxy" })
  )
  depends_on = [aws_instance.ec2-k3s_server]
}