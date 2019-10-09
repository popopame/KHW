# Kubernetes the Hard Way , On-Premise/Baremetal
### Introduction

In this course , we will deploy a Kubernetes Cluster "The Hard Way" on baremetal server , wich mean that we will do everything manually (With script and ansible playbook , to help you do boring task if you want , **but** we will do it mainly with our little hands !).
We will not use heavy-duty tools to deploy an ready-to-use Cluster (like Kops, Kubespray,Minikube, ect...).

Why do this you ask? To Better Understand How Kubernetes Work , and how all of his components interact with each others.
This will be a good exercice if you are preparing the CKA certification , or if you just want to get your hands dirty in Kubernetes.


"Kubernetes : The Hard Way" , is a concept created by Kelsey Hightower on his [Github](https://github.com/kelseyhightower/kubernetes-the-hard-way). It is a really well made guide , but it was thinked to be done ont the Google Cloud Platform Cloud , nonetheless , I recommand you to read this guide.

But if you want to dive in Kubernetes , you might not have acces to GCP ressources (There is a Free tier , but will not suffice for this guide) or , you might want to try on a On-premise environement: And that's exactly what we will do in this course !


### About Me

My name is Gabin , I am 21 years old and currently living in france.
Passionate about new technologies , my goal is to learn new thing everyday and to help people learn too !


### Course Introduction and Tools used
___
### 1. Get started

#### 1.1 Understand How Kubernetes Work: The Big Picture

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
