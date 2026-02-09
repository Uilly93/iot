#!/bin/bash
# Install K3s on the master node
apt update -y && \
apt install curl -y
IP_MASTER=$(ip -4 addr show eth1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=$IP_MASTER --advertise-address=$IP_MASTER --write-kubeconfig-mode 644" sh -

# Make sure kubectl is set up for the vagrant user
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube/config

# Get the token for the worker nodes
TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)

# Store the token for the workers to use
echo $TOKEN > /vagrant/token
