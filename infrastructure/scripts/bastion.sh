#!/bin/bash

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Configure kubectl
aws s3 cp  s3://infra-shakazu-bucket/lifi/config.yaml config.yaml
mkdir ~/.kube
cat config.yaml > ~/.kube/config

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# run terraform apply
cd ../terraform/apps
terraform init
terraform plan
terraform apply --auto-approve
