
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

#### Features 
- 1 Master node
- 2 Worker nodes
- CNI : Calico 
- kubernetes version : latest
- installation tool : kubeadm

After Povisioning the 3 VMs , ssh into each one of them and run these steps :

- Step 1. Turn off the swap & firewall :

  ``` bash
    sudo swapoff -a

    sudo ufw disable
  ```

---
- Step 2. Configure the local IP tables to see the Bridged Traffic

  - Enable the bridged traffic
    ``` bash
      sudo modprobe br_netfilter
    ```

  - Copy the below contents in this file.. /etc/modules-load.d/k8s.conf
    ``` bash
      cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
      br_netfilter
      EOF
    ```
  - Copy the below contents in this file.. /etc/sysctl.d/k8s.conf
    ``` bash
      cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
      net.bridge.bridge-nf-call-ip6tables = 1
      net.bridge.bridge-nf-call-iptables = 1
    EOF
    ```

  - Confirm bridged traffic is enabled on all nodes
    ``` bash
      sudo sysctl --system
    ```
---
- Step 3. Install Docker as a Container RUNTIME

  - Add Docker’s official GPG key:
    ``` bash

      sudo mkdir -p /etc/apt/keyrings

      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    ```

  - Use the following command to set up the repository:
    ``` bash
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    ```
  - Install Docker Engine, containerd, and Docker Compose
    ``` bash
      sudo apt-get update

      sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
    ```
---
  - Step 4 Installing A different Container runtime interface

      since dockershim support stopped from kubernetes v1.24+ and we are installing the latest version of k8s ,
      we need to install a different cri in order for kubelet to communicate with the container runtime in the docker engine (containerd) ,
      therefore we're installing **cri-dockerd** , a cri from mirantis with the collaboration of docker .

      Just follow the steps to install cri-dockerd from this link


        https://github.com/Mirantis/cri-dockerd
---
  - Step 5. Configure Docker Daemon for cgroups management & Start Docker

    - Copy the below contents in this file.. /etc/docker/daemon.json
      ``` bash
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
      ```
      ``` bash
        sudo systemctl daemon-reload
        sudo systemctl restart docker
        sudo systemctl enable docker
        sudo systemctl status docker
      ```
---
  - Step 6. Install kubeadm, kubectl, kubelet

    - Add Kubernetes Signing Key

      Since you are downloading Kubernetes from a non-standard repository, it is essential to ensure that the software is authentic. This is done by adding a signing key.

      On each node, use the curl command to download the key, then store it in a safe place (default is /usr/share/keyrings):
      ``` bash
      curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo tee /usr/share/keyrings/kubernetes.gpg
      ```
    - Add Software Repositories 
      Kubernetes is not included in the default repositories. To add the Kubernetes repository to your list, enter the following on each node:
      ``` bash
      echo "deb [arch=amd64 signed-by=/usr/share/keyrings/kubernetes.gpg] http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list
      ```
      ``` bash
      sudo apt update

      sudo apt install kubeadm kubelet kubectl
      ```

    - Configure kubelet cgroup driver as the container runtime driver

      update kubelet args (KUBELET_KUBECONFIG_ARGS) in /etc/systemd/system/kubelet.service.d/10-kubeadm.conf and add a --cgroup-driver flag

      it should look like this :
      ``` bash
      Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --cgroup-driver=systemd"
      ```

      ``` bash
      sudo systemctl daemon-reload
      sudo systemctl restart kubelet
      ```

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


