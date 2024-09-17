#!/bin/bash

sudo apt update -y
curl -sfL https://get.k3s.io | K3S_URL=https://10.0.20.222:6443 K3S_TOKEN=K10084a794ccd473dd52d802f335ce8b5899674ba9a4e9f9e43a63616438ba937fb::server:650d1423280927884c49b459ca158df6 sh -
