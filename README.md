# Kubernetes

**What willl be installed and configured?**

* A Ubuntu-server will be configured and a number of tools installed here. The server itself is a basic requirement for this tutorial.

* A `kuberenetes` cluster with one node (more can be added) acting as both master and worker called `k8master`.

* Container runtime will  `containerd` didn't work.

* The cluster will use `metallb` version 0.13.1 as its own loadbalancer, because it is **not** running in a cloud environment, which typically supply a loadbalancer service.

* **Bare metal installation** on either a home server or virtual machines (for example using `vagrant` or `proxmox`)

**What are the basic requirements and installations** for the setup used here?

| App. or attribute     | Version or setting | Comments                                                     |
| --------------------- | ------------------ | ------------------------------------------------------------ |
| Ubuntu Server         | 22.04              | The version number of Ubuntu Server has seemed very important. |
| Server IP-range start | 192.168.56.101     | The first (master) server will start a 192.168.56.101, where the '56'-part is due to the use of VirtualBox as provider for Vagrant |
| docker-ce | | |
| docker-ce-cli | | |
| kubeadm               | 1.24.3             | Kubead, kubectl, and kubelet must all be the same version number  |
| kubectl               | 1.24.3             | Kubead, kubectl, and kubelet must all be the same version number                                                             |
| kubelet               | 1.24.3             | Kubead, kubectl, and kubelet must all be the same version number                                                             |
| containerd            | latest           | Consider locking down version number                     |
| calico | 3.18 | |
| metallb | 0.13.4 | Notice, there are important difference between v0.12 and v0.13. |
| cert-manager | | (optional) |
| traefik | | (optional) |
| longhorn | | (optional) |

## Outline of the Kubernetes setup process

The **basic** cluster setup process contains three main steps:

1. Install `ubuntu server 22.04` (for example as a virtual machine on `proxmox` or `vagrant`). See details in vagrant-folder.
2. Basic server configuration with installation of applications and configuration of network, kernel moduels and container runtime. See more notes below. Applications to be installed includes `kubeadm`, `kubectl`, `kubelet`, `containerd`, `docker-ce`, `docker-ce-cli`, and other needed tools for installation.
3. Initialise and configure Kubernetes cluster (skip if joining a cluster). This step starts the cluster and installs `calico` and `metallb` for the basic networking.

Now other servers can be joined to the cluster.

Step 2 and 3 can be accomplised with the script `k8s_ubuntu22_04.sh`.

However, other **recommended** additional features and functionality should be added.

1. Install certificate manager `cert-manager`
2. Install `traefik` for ingress management
3. Install `longhorn` to provide persistent storage

## Basic server configuration (install applications and apps)

Preparing a server for the Kubernetes cluster consists of two main parts:

* Install relevant software packages and add needed repositories
* Configure the server

Install needed **tools and packages**

```bash
# Install needed tools and packages
sudo -i
apt update
apt remove docker docker.io containerd runc
apt install apt-transport-https ca-certificates curl -y

# Add GPG-keys and repositories

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list

curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

apt update
apt install docker-ce docker-ce-cli containerd.io -y
apt install -qq -y kubeadm=1.24.0-00 kubelet=1.24.0-00 kubectl=1.24.0-00
apt-mark hold kubelet kubeadm kubectl
```

Configure **server and services**

```bash
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

vim /etc/containerd/config.toml # remove cri from disabled plugins, if listed
systemctl restart containerd
systemctl enable containerd
sed -i '/swap/d' /etc/fstab
swapoff -a
systemctl disable --now ufw

cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system 
```

## Initialise cluster

**Init**

```bash
sudo kubeadm init \
  --control-plane-endpoint="192.168.56.101:6443" \
  --apiserver-advertise-address="192.168.56.101" \
  --pod-network-cidr="10.244.0.0/16"
```

Now, to manage the cluster as non-root user (with `kubectl --kubeconfig=/etc/kubernetes/admin.conf <command>`) run the following three lines:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Then **untaint nodes** to allow for pod creation. This is not needed if work nodes have joined the cluster, and if they run all pods.

```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane- node-role.kubernetes.io/master-
```

**Install network tool**, `calico`, to enable communication in the cluster.

```bash
kubectl apply -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml
```

**Install loadbalancer**, `metallb`, to handle ip addresses. This is needed for Kubernetes on bare metal.

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.4/config/manifests/metallb-native.yaml
```

Now, **setup the loadbalancer**

Create a yaml-file (for example metallb-settings.yaml) with the following content - or use sample from the metallb-folder:

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.56.200-192.168.56.210
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
```

**Apply** the settings from the yaml-file:

```bash
kubectl apply -f <metallb-settings-file>.yaml
```

## Common additional steps

It is recommended to also add the following to the cluster, as it adds functionality which is normally needed:

* Install `cert-manager`
* Install `traefik`
* Install `longhorn`

