#!/bin/bash

# 1. Удаление развернутого приложения Nginx
kubectl delete deployment nginx
kubectl delete svc nginx

# 2. Удаление сетевого плагина (Flannel)
kubectl delete -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# 3. Удаление кластера Kubernetes
sudo kubeadm reset -f

# 4. Удаление конфигурации kubectl
rm -rf $HOME/.kube

# 5. Отключение и удаление containerd
sudo systemctl stop containerd
sudo systemctl disable containerd
sudo apt remove -y containerd.io

# 6. Удаление пакетов Kubernetes
sudo apt remove -y kubelet kubeadm kubectl
sudo apt autoremove -y

# 7. Восстановление файла /etc/fstab
sudo sed -i '/ swap / s/^#//g' /etc/fstab

# 8. Восстановление настроек ядра
sudo rm /etc/modules-load.d/containerd.conf
sudo rm /etc/sysctl.d/kubernetes.conf
sudo sysctl --system

# 9. Удаление хоста из /etc/hosts
sudo sed -i '/k8s-trainee.test.io/d' /etc/hosts

# 10. Удаление настроек hostname
sudo hostnamectl set-hostname $(hostname -s)

# 11. Включение swap
sudo swapon -a

echo "Все изменения отменены. Система возвращена в исходное состояние."
