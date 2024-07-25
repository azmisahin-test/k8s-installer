İşte Ubuntu'da Kubernetes kurulumunu adım adım açıklayan bir README dosyası:

# Kubernetes Kurulum Rehberi

Bu rehber, Ubuntu 24.04 LTS üzerinde Kubernetes v1.30'u kurmanıza yardımcı olacaktır.

## Gereksinimler

- Ubuntu 24.04 LTS
- Root (sudo) erişimi

## Adımlar

### 1. Depoyu ve Anahtarı Ekleyin

Öncelikle, Kubernetes deposunu eklemek ve GPG anahtarını indirip yapılandırmak için aşağıdaki komutları çalıştırın:

```sh
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo rm -f /etc/apt/sources.list.d/kubernetes.list
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

2. Kubernetes Paketlerini Kurun
Aşağıdaki komutlarla kubeadm, kubelet ve kubectl paketlerini kurun ve bu paketlerin güncellenmesini durdurun:

```sh
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

3. Swap'ı Devre Dışı Bırakın
Kubernetes, swap'ın devre dışı bırakılmasını gerektirir. Aşağıdaki komutları çalıştırarak swap'ı devre dışı bırakın:

```sh
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

4. Kubelet Servisini Etkinleştirin
Kubelet servisini etkinleştirin ve hemen başlatın:

```sh
sudo systemctl enable --now kubelet
``` 

5. Cgroup Sürücüsünü Yapılandırın
Kubelet'in cgroup sürücüsünü systemd olarak yapılandırın ve kubelet servisini yeniden başlatın:

```sh
echo 'KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"' | sudo tee /etc/default/kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

6. Kurulumun Tamamlanması
Kurulum tamamlandığında, aşağıdaki mesajı göreceksiniz:

```sh
Kubernetes v1.30 kurulumunuz tamamlandı. Şimdi kubeadm kullanarak bir küme oluşturabilirsiniz.
```

7. Küme Oluşturma
Kubernetes kümenizi oluşturmak için kubeadm init komutunu kullanabilirsiniz:

```sh
sudo kubeadm init
```

Bu komutu çalıştırdıktan sonra, ekranınıza gelen talimatları izleyerek Kubernetes kümenizi tamamlayabilirsiniz.

Sorun Giderme
Herhangi bir sorunla karşılaşırsanız, aşağıdaki komutlarla ilgili günlük dosyalarını kontrol edebilirsiniz:


```sh
sudo journalctl -xeu kubelet
```

Katkıda Bulunma
Bu rehberi iyileştirmek veya katkıda bulunmak isterseniz, lütfen bir pull request gönderin veya bir issue açın.