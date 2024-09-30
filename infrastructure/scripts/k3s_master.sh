#!/bin/bash

sudo apt update -y

sudo snap install aws-cli --classic

curl -sfL https://get.k3s.io | sh -s - --disable=traefik  --disable=coredns

aws s3 cp s3://infra-shakazu-bucket/lifi/kube-dns.yaml   kube-dns.yaml
sudo kubectl apply -f kube-dns.yaml

sleep 5s

token=$(sudo cat /var/lib/rancher/k3s/server/node-token)
master_ip=$(ip addr | grep 'inet 10.0' | awk '{print $2}' | sed 's/\/.*//g')

cat <<EOF > join.sh
#!/bin/bash
curl -sfL https://get.k3s.io | K3S_URL="https://$master_ip:6443" K3S_TOKEN="$token" sh -
EOF

aws s3 cp join.sh s3://infra-shakazu-bucket/lifi/join.sh



# Send KubeConfig to s3 bucket
sudo cat /etc/rancher/k3s/k3s.yaml > config.yaml

aws s3 cp config.yaml s3://infra-shakazu-bucket/lifi/config.yaml