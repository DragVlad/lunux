#!/bin/bash

# 1. Обновление системы и настройка хоста
sudo apt update -y && sudo apt upgrade -y
sudo hostnamectl set-hostname k8s-trainee.test.io
# важно какой здесь IP!
echo "192.168.1.9 k8s-trainee.test.io k8s-trainee" | sudo tee -a /etc/hosts
sudo systemctl restart systemd-hostnamed

# 2. Отключение swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# 3. Настройка ядра для Kubernetes
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# 4. Установка containerd
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y containerd.io

# Настройка containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# 5. Установка Kubernetes
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# 6. Инициализация кластера
sudo kubeadm init \
  --control-plane-endpoint=k8s-trainee.test.io \
  --pod-network-cidr=10.244.0.0/16 \
  --ignore-preflight-errors=NumCPU

# 7. Настройка kubectl для обычного пользователя
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl cluster-info
kubectl get nodes
kubectl get pods -n kube-system

kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
watch kubectl get pods -n kube-system  # CoreDNS должен перейти в Running
kubectl get nodes                     # Нода должна стать Ready
kubectl get pods -n kube-flannel