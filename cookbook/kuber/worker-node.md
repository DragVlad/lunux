Вижу, у вас уже настроен control-node (мастер нода) на 192.168.0.19, и вы хотите добавить worker-node с IP 192.168.0.18. Команда `cat /etc/hosts` не показала вывод, но это не критично — сейчас разберём, что нужно сделать.

## Что такое Cilium и что нужно для worker-ноды

Cilium — это CNI-плагин для Kubernetes, который работает на **всех** нодах кластера (и на control-plane, и на worker). На worker-ноде Cilium запустится автоматически как DaemonSet после того, как нода присоединится к кластеру. **Отдельно устанавливать Cilium на worker не нужно.**

## Пошаговая настройка worker-ноды

### 1. Подготовка системы (на worker-node)

```bash
# Отключить swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Загрузить модули ядра
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# Настройки sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

### 2. Установка containerd

```bash
sudo apt update
sudo apt install -y containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Включить SystemdCgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd
```

### 3. Установка kubeadm, kubelet, kubectl

```bash
sudo apt install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet
```

### 4. Настройка /etc/hosts (на обеих нодах)

Добавьте на **обеих** машинах (control-node и worker-node):

```bash
# /etc/hosts
192.168.0.19   control-node
192.168.0.18   worker-node
```

### 5. Получить join-команду на control-node

На **control-node** выполните:

```bash
# Если токен истёк — пересоздать
kubeadm token create --print-join-command
```

Вы увидите что-то вроде:
```
kubeadm join 192.168.0.19:6443 --token xxxxx.yyyyyyyyyyyyyyyy \
  --discovery-token-ca-cert-hash sha256:abcdef...
```

### 6. Присоединить worker к кластеру

На **worker-node** выполните полученную команду:

```bash
sudo kubeadm join 192.168.0.19:6443 --token xxxxx.yyyyyyyyyyyyyyyy \
  --discovery-token-ca-cert-hash sha256:abcdef...
```

### 7. Проверка на control-node

```bash
kubectl get nodes -o wide
kubectl get pods -n kube-system -o wide | grep cilium
```

Вы должны увидеть:
- `worker-node` в статусе `Ready`
- Два пода `cilium-xxxxx` (по одному на каждую ноду) в статусе `Running`

Если Cilium не установлен на control-node как DaemonSet — его нужно установить один раз на весь кластер (см. ниже).

## Если Cilium ещё не установлен в кластере

Если на control-node Cilium уже работает, **ничего делать не надо** — DaemonSet сам развернёт под на новой ноде.

Проверить:
```bash
kubectl get ds -n kube-system cilium
```

Если Cilium ещё не установлен:
```bash
# На control-node
helm repo add cilium https://helm.cilium.io/
helm repo update
helm install cilium cilium/cilium --namespace kube-system \
  --set k8sServiceHost=192.168.0.19 \
  --set k8sServicePort=6443
```

---

**Пришлите вывод `cat /etc/hosts`** — посмотрим, что там уже прописано, и подскажу точнее. Также уточните: Cilium уже установлен на control-node (`kubectl get ds -n kube-system`)?