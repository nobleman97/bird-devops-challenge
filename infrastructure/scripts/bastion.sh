#!/bin/bash

ssh-add -D
ssh-add ~/.ssh/k8s

# echo "Type Bastion IP address below:"
# read bastion_ip

# echo "Type k8s master private ip below:"
# read master_ip

master_ip=$(terraform output | grep master | grep -v kubectl | awk '{print $3}' | sed 's/\"//g')
bastion_ip=$(terraform output | grep jumpbox | grep -v kubectl | awk '{print $3}' | sed 's/\"//g')

ssh -L 6443:$master_ip:6443 ubuntu@$bastion_ip
