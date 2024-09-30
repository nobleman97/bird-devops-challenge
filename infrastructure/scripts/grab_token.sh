#!/bin/bash

lb_dns_name=$(terraform output | grep 'alb-dns-name =' | awk '{print $3}' | sed 's/\"//g')
aws s3 cp s3://infra-shakazu-bucket/lifi/config.yaml config.yaml 

sed -i "s|https://127.0.0.1|http://$lb_dns_name|g" config.yaml 

aws s3 cp config.yaml s3://infra-shakazu-bucket/lifi/config.yaml 