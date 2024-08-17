data "aws_key_pair" "Terraform" {
  key_name = "Terraform"
  filter {
    name   = "key-name"
    values = ["Terraform"]
  }
}

