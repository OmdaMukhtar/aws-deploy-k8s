#!/bin/bash

set -euo pipefail

# Install Docker & Kubernetes
apt-get update
apt-get install -y docker.io curl apt-transport-https gnupg unzip

# Add Kubernetes repository (v1.30 stable)
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl

# Initialize Kubernetes master
kubeadm init --pod-network-cidr=${pod_network_cidr}

# Configure kubectl for the ubuntu user
mkdir -p /home/ubuntu/.kube
cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

# Install Flannel CNI (with retry in case of race conditions)
for i in {1..5}; do
  su - ubuntu -c "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml" && break || sleep 10
done

# Generate join command
kubeadm token create --print-join-command > /home/ubuntu/join.sh
chmod +x /home/ubuntu/join.sh

# Install AWS CLI v2
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws

# Upload join command to SSM Parameter Store
aws ssm put-parameter \
  --name "/k8s/join-command" \
  --value "$(cat /home/ubuntu/join.sh)" \
  --type "String" \
  --overwrite \
  --region ${aws_region}
