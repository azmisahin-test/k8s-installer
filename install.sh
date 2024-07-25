#!/bin/bash
# install.sh
# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Ensure curl is installed
echo -e "${GREEN}Step 0: Ensuring curl is installed${NC}"
sudo apt update
sudo apt install -y curl

# Detect OS
os=$(lsb_release -is)

# Package manager and update commands
if [ "$os" = "Ubuntu" ] || [ "$os" = "Debian" ]; then
  package_manager="apt"
  update_command="sudo apt update"
  docker_install_command="curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io"
elif [ "$os" = "CentOS" ]; then
  package_manager="yum"
  update_command="sudo yum update"
  docker_install_command="sudo yum install -y yum-utils && sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo && sudo yum install -y docker-ce docker-ce-cli containerd.io"
fi

# Kubernetes version (default: 1.24)
kubernetes_version=${1:-1.24}

# Pod network (default: calico)
pod_network=${2:-calico}

# Proxy settings (default: none)
proxy=${3:-}

# Update packages
echo -e "${GREEN}Step 1: Updating Packages${NC}"
$update_command
sudo $package_manager upgrade -y

# Install Docker
echo -e "${GREEN}Step 2: Installing Docker${NC}"
$docker_install_command
sudo systemctl enable docker
sudo systemctl start docker

# Proxy settings
if [ -n "$proxy" ]; then
  echo -e "${GREEN}Step 3: Setting Proxy${NC}"
  echo "export http_proxy=$proxy" >> ~/.bashrc
  echo "export https_proxy=$proxy" >> ~/.bashrc
  source ~/.bashrc
fi

# Add Kubernetes repository
echo -e "${GREEN}Step 4: Adding Kubernetes Repository${NC}"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo tee /etc/apt/sources.list.d/kubernetes.list <<EOF
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo $update_command

# Install Kubernetes components
echo -e "${GREEN}Step 5: Installing Kubernetes Components${NC}"
sudo $package_manager install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Initialize Kubernetes cluster
echo -e "${GREEN}Step 6: Initializing Kubernetes Cluster${NC}"
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# User configuration
echo -e "${GREEN}Step 7: Configuring User${NC}"
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Add Pod network
echo -e "${GREEN}Step 8: Adding Pod Network${NC}"
if [ "$pod_network" = "calico" ]; then
  kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
else
  echo "Unsupported pod network: $pod_network"
  exit 1
fi

echo -e "${GREEN}Kubernetes Cluster Installation Completed!${NC}"
echo "Use the IP address of the master node to join other nodes."
