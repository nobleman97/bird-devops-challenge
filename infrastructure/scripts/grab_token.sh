#!/bin/bash

# Load the right key
ssh-add -D
ssh-add ~/.ssh/k8s

# echo "Type Bastion IP address below:"
# read bastion_ip

# echo "Type k8s master private ip below:"
# read master_ip

master_ip=$(terraform output | grep master | awk '{print $3}' | sed 's/\"//g')
bastion_ip=$(terraform output | grep jumpbox | awk '{print $3}' | sed 's/\"//g')

echo "What do you want to do? (Type in a number)"
echo "1.) Get k3s Join Token"
echo "2.) Get Kube Config"
echo "3.) Both"
read action


if [ $action -eq 1 ]; then
    # Grab the join Token
    ssh -o ProxyCommand="ssh ubuntu@$bastion_ip -W %h:%p" ubuntu@$master_ip 'sudo cat /var/lib/rancher/k3s/server/node-token'
elif [ $action -eq 2 ]; then
    # Grab KubeConfig
    ssh -o ProxyCommand="ssh ubuntu@$bastion_ip -W %h:%p" ubuntu@$master_ip 'sudo cat /etc/rancher/k3s/k3s.yaml'

elif [ $action -eq 3 ]; then
    ssh -o ProxyCommand="ssh ubuntu@$bastion_ip -W %h:%p" ubuntu@$master_ip 'sudo cat /var/lib/rancher/k3s/server/node-token'

    echo "---- DO NOT COPY THIS LINE -----"

    ssh -o ProxyCommand="ssh ubuntu@$bastion_ip -W %h:%p" ubuntu@$master_ip 'sudo cat ~/.kube/config'
else
    echo "Looks like you entered an invalid figure"
fi


