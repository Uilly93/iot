#!/bin/bash
# Get the master node's IP from the arguments

MASTER_IP=$1
IP_WORKER=$(ip -4 addr show eth1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
# MASTER_IP="192.168.56.110"

apt update -y && apt install curl -y 
# Get the token from the shared folder

echo "Waiting for token from server"
until [ -f /vagrant/token ]; do
	sleep 1
done

TOKEN=$(cat /vagrant/token)

# Install K3s agent (worker) and join the master node
curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$TOKEN INSTALL_K3S_EXEC="agent --node-ip=$IP_WORKER" sh -
echo "K3s installed succesfuly"