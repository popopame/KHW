#### 4.1  What is the Kubernetes Control Planes? How does it work?

#### 4.2 Download the files

**NOTE: As usual , all commands must be done on all 3 clusters**


First , we need to download  the binaries needed for the Chapter , once downloaded , put them in the ```/usr/bin``` folder , so we can execute them.

```bash
mkdir -p /etc/kubernetes/config

wget --secure-protocol=auto\
  "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubectl"

  chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl

  mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/bin/


```
___
**In the 4.4 , 4.4 & 4.5 chapter , we will configure the the service file for each kubebernetes components , as for the etcd one be *very* carefull of the syntax**
___


#### 4.3 Configuring the API server

#### 4.4 Configuring the Kubernetes Controller Manager

#### 4.5 Configuring the Kubernetes scheduler

#### 4.6 Enabling HTTP Health Check

#### 4.7 RBAC
