#Step 1: EC2 JumpBox start

resource "aws_security_group" "sgp-jumpbox" {
  name        = "tf-sg-colending-mdev-001"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id
  #   ingress {
  #     description = "Connectivity from VPN to AWS"
  #     from_port   = 22
  #     to_port     = 22
  #     protocol    = "tcp"
  #     cidr_blocks = [var.vpn_cidr]
  #   }
  ingress {
    description = "Connectivity from VPN to AWS"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "All Traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-sg-ec2-jumpbox"
  }
}
# #Step ssm role
# resource "aws_iam_role" "ssm_role" {
#   name        = "tf-ssm-role"
#   description = "Role for SSM"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#         Effect = "Allow"
#       }
#     ]
#   })
# }
# resource "aws_iam_policy_attachment" "ssm_attach" {
#   name       = "tf-ssm-attach"
#   roles      = [aws_iam_role.ssm_role.name]
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }
# resource "aws_iam_instance_profile" "ssm_profile" {
#   name = "tf-ssm-profile"
#   role = aws_iam_role.ssm_role.name
# }


resource "aws_instance" "web-colending" {
  ami                         = "ami-068e0f1a600cd311c"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.sgp-jumpbox.id]
  subnet_id                   = aws_subnet.Blazeclan-MSteam1-public-1a.id
  associate_public_ip_address = true
  key_name                    = data.aws_key_pair.Terraform.key_name
  disable_api_termination     = true
  #iam_instance_profile       = aws_iam_instance_profile.ssm_profile.name
  user_data = file("data.sh")


  root_block_device {
    volume_size = 50 # in GB 
  }
  tags = merge(
    {
      "Name" : "tf-jumpbox"
      #"Backup" = "true"
    }
  )
  depends_on = [
    aws_security_group.sgp-jumpbox
  ]
  metadata_options {
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
    http_endpoint               = "enabled"
    instance_metadata_tags      = "enabled"
  }
}
#Step 1: EC2 JumpBox End