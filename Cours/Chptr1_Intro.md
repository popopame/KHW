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
That's why i'm so found about the Open Source community.


###  Tools used
As we said earlier , we will do it the "hard way" , so , there is no "obligatory tools" (minus the servers on wich we will deploy kubernetes) , **but**  you can use tool to help you along the way , or to speed up the process (if you wan't to restart again an you wan't to skip boring part).

I will give you bash script and some Ansible playbook **Theses will not help you deploy the cluster** , but they might speed up tidious task (like deploying same files on distants hosts , install package ,generating certificate , ect...). If you do not want to use the script you can do everything by hand.

I also recommend using tmux , a package that can help execute the same command on differents hosts , wich will be really helpfull.
___
### 1. Get started

#### 1.1 Understand How Kubernetes Work: The Big Picture

The first thing to understand is how Kubernetes work in the Big Picture , we are not going to Deep-Dive into it , but a basic understanding is mendatory.

We will describe the big physical components of the cluster : Masters nodes and Worker nodes.
Then we will describe what logical components are stored on these , and how they interact.

**Notes: In this courses I will use the term "Slaves Nodes" and "Worker Node" interchangeably**

There is two main components in a Kubernetes Cluster the *Master nodes* and the *Worker Nodes* :
* **Master Nodes** :  contain the *Controle Plane* it's what controls the cluster an make it function , it consist of multiple sub-components that interact together. They all can be installed on the same master , or split accross multiple node , to make that the Cluster is Highly available.


* **Worker Nodes** : The nodes are the physical components on wich the real application are ran , they are the Muscles of the cluster.

And , on these physical components , run the logical components:

**On the Master nodes**
As said before , the master nodes run the Control Plane , the components of it are:

* **API Server** : The API Endpoint used by all the Others components of Kubernetes to comunicate together
* **Controller Manager** : Perform action at the cluster level : Checking the worker nodes, managing node failure , replicating services in case of failure.
* **Scheduler** : Wich schedule your deployed apps : make them run on a worker node , check for error, ect...
* **etcd** : Wich is a datastore that save persistenly store the cluster configuration.

Here is a Schema to better understand how it work:


**On the worker nodes**

As said before the worked node are the machines that run your contenairized apps , the components that do this are:
* **Container Runtime** : The Container Engine that will run you container (Docker , rkt , CrI-O, ect...). You can choose any CRI compliant Container Runtime that suit your need
* **Kubelet** Wich will talk to the API server and manage the container on the worker node
* **Kubernetes Service Proxy or kube-proxy**: wich will do the load-balancing between the application components/



#### 1.2 What will our Cluster Look like

I created 6 compute instances:
* ***3 Slaves*** : Each one with 2 cores , 4 Go of RAM and 30Go of Disk space
* ***3 Masters*** : Each one with 4 cores , 8Go of RAM and 30Go of Disk Space

I created all of these on my Lab Server , with Proxmox Installed on it.
If you do not have access to a spare server , you do not have a Homelab and you don't want to rent for a server you can deploy this infrastrucre on your computer n just adjust the number and configuration of the instance.
You can for example , run only one master and one Slave.

**Note: If you change the number of deployed instances , don't forget to adapt all the thing we will do on this course to correspond to your infra**


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
