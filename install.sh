#!/bin/bash

set -e

# Renkli çıktılar için tanımlar
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Adım 1: Gerekli Paketlerin Güncellenmesi ve Kurulması${NC}"
sudo apt update
sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl

echo -e "${GREEN}Adım 2: Docker Kurulumu${NC}"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker

echo -e "${GREEN}Adım 3: Kubernetes Kurulumu${NC}"
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo -e "${GREEN}Adım 4: Kubernetes Kümesini Başlatma${NC}"
sudo kubeadm init

echo -e "${GREEN}Adım 5: Kullanıcı Konfigürasyonu${NC}"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo -e "${GREEN}Adım 6: Pod Network Eklenmesi${NC}"
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

echo -e "${GREEN}Kubernetes Kümesi Kurulumu Tamamlandı!${NC}"
