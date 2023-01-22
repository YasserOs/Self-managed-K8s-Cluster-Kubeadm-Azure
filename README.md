
# Bare Metal K8s Cluster on Azure with Terraform and Kubeadm


### Technical Objective 
To implement 3 VMs using Terraform and then install Kubernetes cluster using Kubeadm.

### Environment 
Microsoft Azure Public Cloud

---

## Decscription

### Part 1 : Terraform 

Using Terraform modules , variables and tfvars files to provision 3 VMs in an efficient and generic way

#### Modules

- Network
  - Creates : 1 Virtual net and 1 subnet 
  - Output : Subnet id 

- NSG
  - Creates : 1 Network Security Group and 1 security rule
  - Outputs : Nsg id  
- PublicIP
  - Creates : 1 Public ip
- Vms 
  - Creates : 1 linux virtual machine , 1 network interface card , 1 association between Nsg and Nic


#### Installation 

After pulling the repo , cd into it and create your own terraform.tfvars file to provide values for the variables.tf file

then


```bash
  terraform init
```

to install azure's provider plugins and to initialize the modules

then run 
```bash 
  terraform apply
```
check the output of the apply before confirming with yes and make sure the required resources are created with the values provided in the terraform.tfvars file .

---

### Part 2 : Installing Kubernetes 

After Povisioning the 3 VMs , ssh into each one of them and run these steps :

Step 1. Turn off the swap & firewall :

sudo swapoff -a

sudo ufw disable

==============================================================================
Step 2. Configure the local IP tables to see the Bridged Traffic

2.a Enable the bridged traffic
sudo modprobe br_netfilter

2.b Copy the below contents in this file.. /etc/modules-load.d/k8s.conf

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF


2.c Copy the below contents in this file.. /etc/sysctl.d/k8s.conf

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

2.d confirm bridged traffic is enabled on all nodes

sudo sysctl --system

==============================================================================
Step 3. Install Docker as a Container RUNTIME

3.1 Add Docker’s official GPG key:

sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg


3.2 Use the following command to set up the repository:

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
3.3 Install Docker Engine, containerd, and Docker Compose

sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

==============================================================================
Step 4. Configure Docker Daemon for cgroups management & Start Docker

4.a Copy the below contents in this file.. /etc/docker/daemon.json

cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker
sudo systemctl status docker

==============================================================================
Step 5. Install kubeadm, kubectl, kubelet

5.1 Add Kubernetes Signing Key

Since you are downloading Kubernetes from a non-standard repository, it is essential to ensure that the software is authentic. This is done by adding a signing key.

On each node, use the curl command to download the key, then store it in a safe place (default is /usr/share/keyrings):

curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo tee /usr/share/keyrings/kubernetes.gpg

5.2 Add Software Repositories 
Kubernetes is not included in the default repositories. To add the Kubernetes repository to your list, enter the following on each node:

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/kubernetes.gpg] http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list

5.3 Kubernetes Installation Tools

sudo apt update

sudo apt install kubeadm kubelet kubectl


## 5.4 Disable AppArmor if problems occur
## sudo systemctl disable apparmor

5.4 Configure kubelet cgroup driver as the container runtime driver

update kubelet args (KUBELET_KUBECONFIG_ARGS) in /etc/systemd/system/kubelet.service.d/10-kubeadm.conf and add a --cgroup-driver flag

it should look like this :

Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --cgroup-driver=systemd"

sudo systemctl daemon-reload
sudo systemctl restart kubelet

============================================================================
Installing CRI from mirantis through this link 
https://github.com/Mirantis/cri-dockerd

follow steps to install cri-dockerd
============================================================================
Step 6. initialize the control plane using kubeadm
on the master node of choice run this command

sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --cri-socket=unix:///var/run/cri-dockerd.sock
(the pod network cidr depends on the networking add on of choice , here its for calico)

and after successfull initialization follow the output steps to create kubeconfig file and enable kubectl to communicate with the api-server

6.1 Install pod networking add on (Calico)
curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml -O

kubectl apply -f calico.yaml

6.2 run the kubeadm join command on each worker node with the correct cri-socket 

==================================================================
Step 7 (Optional) Manage the cluster through your local machine using kubectl and ssh-tunneling
scp linkdc@40.127.106.16:~/.kube/config .

copy config file info into local machine ~/.kube/config file to add the cluster info 

Repoint the api server to : localhost’ s port 6443:

kubectl config set clusters.kubernetes.server htps://127.0.0.1:6443

Repoint the tls server to the clusterip of the kubernetes service. Otherwise certificate error is generated because the only IPs that are included in the apiserver certificate is the actual apiserver IP and the internal clusterIP of the api service (which is 10.96.0.1)

kubectl config set clusters.kubernetes.tls-server-name 10.96.0.1

open port 6443 (or any port you want to forward) on local machine ( if not opened )

sudo ufw allow 6443

Instantiate the ssh tunnel :
ssh -N -L 6443:localhost:6443 linkdc@40.127.106.16

open a new terminal and start running the kubectl commands

after this you can manage your cluster from your local machine easily using kubectl through ssh tunneling


