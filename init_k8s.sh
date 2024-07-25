#!/bin/bash

set -e

# Gereksinimlerin kontrol edilmesi
if [ "$(id -u)" -ne 0 ]; then
  echo "Bu script'i root olarak çalıştırmalısınız."
  exit 1
fi

if [ ! -f /etc/kubernetes/admin.conf ]; then
  echo "Kubernetes admin.conf dosyası bulunamadı. Lütfen Kubernetes kurulumunu tamamladığınızdan emin olun."
  exit 1
fi

# Kubernetes kümesini başlatma
echo "Kubernetes kümesini başlatıyorum..."
kubeadm init --pod-network-cidr=10.244.0.0/16

# Kubernetes yapılandırma dosyasını kullanıcıya kopyalama
echo "Kubernetes yapılandırma dosyasını kopyalıyorum..."
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Pod network eklentisini kurma
echo "Pod network eklentisini kuruyorum..."
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Worker node'ları kümeye ekleme talimatlarını gösterme
echo "Worker node'ları kümeye eklemek için gerekli komutu aşağıda bulabilirsiniz."
kubeadm token create --print-join-command

echo "Kubernetes kümesi başlatıldı ve yapılandırıldı. Lütfen yukarıdaki komutu worker node'larınızda çalıştırarak kümenize ekleyin."
