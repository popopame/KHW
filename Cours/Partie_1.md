# Kubernetes the Hard Way , On-Premise/Baremetal
### 1.Intro

___

### 2.Creation of the computes instances

### 3.Installation of the tools
#### What we will install

We will need 3 tools installed on the Bastion host:
* ***cfssl***: is CloudFlare PKI/TLS toolkit , wich will help create the certificates
* ***cfssljson***: the cfssljson will take the JSON output from cfssl , and will write the generated certificate to the disk.
* ***kubectl***: This is the Kubernetes command-line tool , your best-friend during this course.

#### Install the Packet

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

### 4.Generate the certificate

We will now generate a PKI infrastructure , and create all the certificate for
the kubernetes cluster.

#### 4.1 What is a PKI infrastructure ?


#### 4.2 Onto the creation !


### 4.3 Deploy the certificate

```ansible-playbook -i inventory/hosts.yml -u root -k deploiement.yaml```
