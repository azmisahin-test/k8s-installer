#!/bin/bash

# Renkler için tanımlamalar
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# İşletim sistemini tespit etme
os=$(lsb_release -is)

# Paket yöneticisi ve komutları ayarlama
if [ "$os" = "Ubuntu" ]; then
  package_manager="apt"
  update_command="apt update"
  docker_install_command="curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" && sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io"
elif [ "$os" = "Debian" ]; then
  package_manager="apt"
  update_command="apt update"
  docker_install_command="curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add - && sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable\" && sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io"
elif [ "$os" = "CentOS" ]; then
  package_manager="yum"
  update_command="yum update"
  docker_install_command="sudo yum install -y yum-utils && sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo && sudo yum install docker-ce docker-ce-cli containerd.io"
fi

# Kubernetes sürümü (varsayılan: 1.24)
kubernetes_version=${1:-1.24}

# Pod networkü (varsayılan: calico)
pod_network=${2:-calico}

# Proxy ayarları (varsayılan: yok)
proxy=${3:-}

# Gerekli paketleri güncelleme
echo -e "${GREEN}Adım 1: Gerekli Paketlerin Güncellenmesi${NC}"
sudo $package_manager update
sudo $package_manager upgrade -y

# Docker kurulumu
echo -e "${GREEN}Adım 2: Docker Kurulumu${NC}"
$docker_install_command

# Proxy ayarları (varsa)
if [ -n "$proxy" ]; then
  echo -e "${GREEN}Adım 3: Proxy Ayarları${NC}"
  echo "export http_proxy=$proxy" >> ~/.bashrc
  echo "export https_proxy=$proxy" >> ~/.bashrc
  source ~/.bashrc
fi

# Kubernetes depo ekleme
echo -e "${GREEN}Adım 4: Kubernetes Depo Ekleme${NC}"
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-$kubernetes_version main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo $package_manager update

# Kubernetes bileşenlerini yükleme
echo -e "${GREEN}Adım 5: Kubernetes Bileşenlerinin Yüklemesi${NC}"
sudo $package_manager install -y kubelet kubeadm kubectl
sudo $package_manager mark hold kubelet kubeadm kubectl

# Kubernetes kümesini başlatma
echo -e "${GREEN}Adım 6: Kubernetes Kümesinin Başlatılması${NC}"
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Kullanıcı konfigürasyonu
echo -e "${GREEN}Adım 7: Kullanıcı Konfigürasyonu${NC}"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Pod networkü ekleme
echo -e "${GREEN}Adım 8: Pod Networkü Ekleme${NC}"
if [ "$pod_network" = "calico" ]; then
  kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
else
  echo "Desteklenmeyen pod networkü: $pod_network"
  exit 1
fi

echo -e "${GREEN}Kubernetes Kümesi Kurulumu Tamamlandı!${NC}"
echo "Master düğümünün IP adresini kullanarak diğer düğümleri kümeye katın."
