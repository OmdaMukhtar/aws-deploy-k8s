#!/bin/bash
set -e

apt-get update
apt-get install -y docker.io curl apt-transport-https gnupg2 ca-certificates sshpass

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor | tee /usr/share/keyrings/kubernetes-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl

# Join the cluster using injected command
${kubeadm_join_command}
