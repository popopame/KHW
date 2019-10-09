### 2 Provisioning the CA and Generating the TLS certificates

#### 2.1 What are CA/TLS and why do we need them ?

#### 2.2 CA/TLS in a Kubernetes cluster

#### 2.3 Generate the CA

#### 2.4 Generate the certificate

#### 2.5 Deploy the certificates

We will now generate a PKI infrastructure , and create all the certificate for
the kubernetes cluster.


```ansible-playbook -i inventory/hosts.yml -u root -k deploiement.yaml```
