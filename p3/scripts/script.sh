#!/bin/bash

APP="myapp"
NAMESPACE_PROJET="dev" # Le namespace défini dans ton YAML unique
DEPLOY_NAME="wil-playground" # Le nom du déploiement dans ton YAML unique
PORT=8080
CLUSTER_NAME="p3"

# if [ ! -f ~/.kube/config ]; then
#     echo "Configuring kube ..."
#     mkdir -p ~/.kube
# else
#     echo "Kubeconfig already setup"
# fi
# export KUBECONFIG=~/.kube/config
# sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
# sudo chown $(id -u):$(id -g) ~/.kube/config
# set -e

if ! k3d cluster list | grep "$CLUSTER_NAME" > /dev/null; then
    echo "Cluster '$CLUSTER_NAME' not found. Creating it..."
    # k3d cluster create $CLUSTER_NAME --api-port 6550 -p "8888:8888@loadbalancer" --agents 1
    # echo "waiting for cluster init..."
    # sleep 5
else
    echo "deleting and recreating cluster"
    k3d cluster delete $CLUSTER_NAME
fi
k3d cluster create $CLUSTER_NAME --api-port 6550 -p "8888:8888@loadbalancer" --agents 1
echo "waiting for cluster init..."
kubectl wait --for=condition=Ready nodes --all --timeout=60s > /dev/null 2>&1
# sleep 5

if ! kubectl get deployment argocd-server -n argocd &> /dev/null; then
    echo "Argo CD not installed. Installing..."
else
    kubectl delete namespace argocd
    echo "Argo CD already installed"
fi
kubectl create namespace argocd 2>/dev/null
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml > /dev/null 2>&1
echo "Waiting for Argo CD components to be ready..."
# kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s > /dev/null 2>&1

if kubectl get application $APP -n argocd &> /dev/null; then
    echo "Deleting previous app..."
    kubectl delete application $APP -n argocd --cascade=foreground
    echo "Waiting for application deletion..."
    kubectl wait --for=delete application/$APP -n argocd --timeout=60s
fi
echo "Applying new app..."
kubectl apply -f ../confs/argocd/app-project.yaml
kubectl apply -f ../confs/argocd/argocd-app.yaml

echo "Waiting for project deployment to be available..."
sleep 2
kubectl wait --for=condition=available --timeout=120s deployment/$DEPLOY_NAME -n $NAMESPACE_PROJET
echo "Port-forwarding on port $PORT..."
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; then
    echo "Port-forward not found or port $PORT used. Resetting..."
    PID=$(lsof -t -i:$PORT)
    [ -n "$PID" ] && kill -9 $PID && sleep 1
fi
kubectl port-forward svc/argocd-server -n argocd $PORT:443 > /dev/null 2>&1 &
sleep 3

# if ps aux | grep -v grep | grep "port-forward svc/argocd-server" > /dev/null; then
#     echo "Port-forwarded succesfuly on port $PORT"
PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "------------------------------------------------------"
echo "project is deployed and ready."
echo "URL: https://localhost:$PORT"
echo "User: admin"
echo "Password: $PASS"
echo "------------------------------------------------------"
# else
#     echo "Error while port-forwarding"
# fi