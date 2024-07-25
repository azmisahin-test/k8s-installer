#!/bin/bash

set -e

# Gereksinimlerin kontrol edilmesi
if [ "$(id -u)" -ne 0 ]; then
  echo "Bu script'i root olarak çalıştırmalısınız."
  exit 1
fi

if [ "$(lsb_release -is)" != "Ubuntu" ]; then
  echo "Bu script yalnızca Ubuntu sistemlerinde çalıştırılabilir."
  exit 1
fi

# Gerekli paketlerin kurulması
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg

# Eski Kubernetes APT deposunun kaldırılması
if [ -f /etc/apt/sources.list.d/kubernetes.list ]; then
  rm /etc/apt/sources.list.d/kubernetes.list
fi

# Kubernetes APT deposunun eklenmesi
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

# kubeadm, kubelet ve kubectl kurulumu
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Swap'ın devre dışı bırakılması
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# kubelet servisini etkinleştirme
systemctl enable --now kubelet

# cgroup sürücüsünün yapılandırılması
echo 'KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"' > /etc/default/kubelet
systemctl daemon-reload
systemctl restart kubelet

# Kurulum tamamlandı
echo "Kubernetes v1.30 kurulumunuz tamamlandı. Şimdi kubeadm kullanarak bir küme oluşturabilirsiniz."
