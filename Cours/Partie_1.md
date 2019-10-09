# Kubernetes the Hard Way , On-Premise/Baremetal
### Introduction
### About Me

### Course Introduction and Tools used
___
### 1. Get started

#### 1.1 Understand How Kubernetes Work

#### 1.2 What will our Cluster Look like

I created 6 compute instances:
* ***3 Slaves*** : Each one with 2 cores , 4 Go of RAM and 30Go of Disk space
* ***3 Masters*** : Each one with 4 cores , 8Go of RAM and 30Go of Disk Space

I created all of these on my Lab Server , with Proxmox Installed on it.
If you do not have access to a spare server , you do not have a Homelab and you don't want to rent for a server you can deploy this infrastrucre on your co


#### 1.3 Setting up your compute instance and tools


First we download the program , the two cfssl packet come from the Kubernetes the Hard Way github
and the kubectl one come from google website
```
wget -q --show-progress --https-only --timestamping \
  https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/linux/cfssl \
  https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/linux/cfssljson \
  https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl
```
Then , we make the programs executables and moves theme to the Bin folder ,
so we can call them via the linux CLI
```
chmod +x cfssl cfssljson kubectl
mv cfssl cfssljson kubectl /usr/local/bin
```


### 2 Provisioning the CA and Generating the TLS certificates

#### 2.1 What are CA/TLS and why do we need them ?

#### 2.2 CA/TLS in a Kubernetes cluster

#### 2.3 Generate the CA

#### 2.4 Generate the certificate

#### 2.5 Deploy the certificates

We will now generate a PKI infrastructure , and create all the certificate for
the kubernetes cluster.


```ansible-playbook -i inventory/hosts.yml -u root -k deploiement.yaml```
