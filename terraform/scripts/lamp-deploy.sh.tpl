#!/bin/bash

set -e

export KUBECONFIG=/home/ubuntu/.kube/config

# Wait until API is ready
until kubectl get nodes; do
    echo "Waiting for Kubernetes API to become available..."
    sleep 10
done

cd /home/ubuntu/kubernetes

kubectl apply -f mysql/
kubectl apply -f apache/
kubectl apply -f php/
