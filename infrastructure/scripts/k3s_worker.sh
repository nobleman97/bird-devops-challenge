#!/bin/bash

sudo apt update -y
sleep 3s
sudo snap install aws-cli --classic

aws s3 cp s3://infra-shakazu-bucket/lifi/join.sh  join.sh

sudo chmod u+x join.sh

./join.sh
