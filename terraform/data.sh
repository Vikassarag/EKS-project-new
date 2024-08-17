#!/bin/bash

# Download the kubectl binary and its SHA256 checksum file
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.29.3/2024-04-19/bin/linux/amd64/kubectl
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.29.3/2024-04-19/bin/linux/amd64/kubectl.sha256

# Verify the downloaded kubectl binary against the checksum
sha256sum -c kubectl.sha256

# Validate the SHA256 hash of the kubectl binary (you may need to adjust this line if openssl is not available)
openssl sha1 -sha256 kubectl

# Make the kubectl binary executable
chmod +x ./kubectl

# Create the bin directory in the user's home directory and move the kubectl binary there
mkdir -p $HOME/bin
cp ./kubectl $HOME/bin/kubectl

# Add the bin directory to the PATH environment variable
export PATH=$HOME/bin:$PATH

# Make the PATH change persistent by adding it to .bashrc
echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc

# Configure AWS CLI
# Replace <aws_access_key_id>, <aws_secret_access_key>, <default_region> and <output_format> with your actual values




# Update kubeconfig for the specified EKS cluster
# Replace 'region-code' with your actual AWS region code
# Replace 'my-cluster' with your actual EKS cluster name
aws eks update-kubeconfig --region ap-south-1 --name tf-eks-cluster
