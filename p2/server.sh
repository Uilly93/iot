#!/bin/bash
apt update -y && \
apt install curl -y
IP_MASTER=$(ip -4 addr show eth1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=$IP_MASTER --advertise-address=$IP_MASTER --write-kubeconfig-mode 644" sh -

mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube/config

until kubectl get serviceaccount default &> /dev/null; do sleep 2; done

kubectl apply -f /vagrant/pods/app1.yaml
kubectl apply -f /vagrant/pods/app2.yaml
kubectl apply -f /vagrant/pods/app3.yaml
kubectl apply -f /vagrant/pods/ingress.yaml