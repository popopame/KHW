### 2 Provisioning the CA and Generating the TLS certificates

As the previous section , we are not going to deep dive into CA/TLS , I will provide here a basic understanding of the topic.

The basics will help us trougought this course , but I Higly recommend you to continue learning on this topic.

CA and certificates are used everywhere in IT nowadays , really understading how these work will be a huge help for you.

We will use the cfssl , wich is a toolboox created by cloudfare to generate PKI.

#### 2.1 What are CA/TLS and why do we need them ?

A **Certificate** is used to confirm an **identities**
In this section we are going to provide **identities** to our kubernetes services.

In IT an Identities is Provided by a **Certificate** and this certificate is validated by  **Certificate Identity**

So we will generate a CA (Certificate Authority) and this CA will be used to sign x.509 compliant **Certificate**.

These Certificate , will be used to confirm the identity of the entity that hold it.



#### 2.2 CA/TLS in a Kubernetes cluster

That's cool , but what is the use of a PKI and certificate in a Kubernetes Cluster?

Remember this schema ?

Well to put it simply , Certificate will be used by all these component to securely communicate together.
The certificates will be used to encrypt the data being exchanged and the CA will be used to validate the identity of the the components.

We will generate the following Certificates:

* **Component/Client Certificate** : These Certs provide authentification for users in the K8s cluster : kube-controller, kube-proxy, kube-scheduler , kubelet and Admin
* **Service account Key** : K8s use a certificate to sign service accoun token
* **Kubernetes API certificate** : Certificate used by the Kubernetes api



**Note: I created a Script to help generate all the Certificates in a faster manner , the most important thing is to UNDERSTAND  a command.
If you do not use the script , you need to declare all the varialble beforehand**

```bash
TLS_C="FR"
TLS_L="Neuilly-Plaisance"
TLS_OU="Kubernetes The Hard Way"
TLS_ST="Seine-Saint-Denis"
declare -a SLAVES_IPS=("10.98.0.104" "10.98.0.105" "10.98.0.106")
declare -a SLAVES_HOSTNAMES=("slave01" "slave02" "slave03")
EXTERNAL_IP=$(curl -s -4 https://ifconfig.co)
```

#### 2.3 Generate the CA

We will create our own CA , you could also use. an already existing CA.
But for learning purpose I Highly recomend creating you own  CA.
To understand how this work


```bash
cat > pki/ca/ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF


cat > pki/ca/ca-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "${TLS_C}",
      "L": "${TLS_L}",
      "O": "kubernetes",
      "OU": "${TLS_OU}",
      "ST": "${TLS_ST}"
    }
  ]
}
EOF

cfssl gencert -initca pki/ca/ca-csr.json | cfssljson -bare pki/ca/ca

```
The CA (Certificate Authority) will be used to validate all the other certificates we will create.

Once the CA is created , it will be used to create all the othe certs.

#### 2.4 Generate the others certificates

We will then create all the certificate for all the component of the cluster

```bash

#Below we will generate the Admin certificate
cat > pki/admin/admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "${TLS_C}",
      "L": "${TLS_L}",
      "O": "system:masters",
      "OU": "${TLS_OU}",
      "ST": "${TLS_ST}"
    }
  ]
}
EOF

cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -profile=kubernetes \
  pki/admin/admin-csr.json | cfssljson -bare pki/admin/admin

#Now we will create a worker certificate for the kubelets on each node
#Each kubelet certifcat must have a certificate containing their hostnames , private IP and Public IP
#On my scenatio , the node are in a private NAT , I only declare their hostnames and Private IP. I use a for loop to do so


for i in {0..2}; do

  cat > pki/clients/${SLAVES_HOSTNAMES[$i]}-csr.json <<EOF
{
  "CN": "system:node:${SLAVES_HOSTNAMES[$i]}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "${TLS_C}",
      "L": "${TLS_L}",
      "O": "system:nodes",
      "OU": "${TLS_OU}",
      "ST": "${TLS_ST}"
    }
  ]
}
EOF

cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -hostname=${SLAVES_HOSTNAMES[$i]},${SLAVES_IPS[$i]},${EXTERNAL_IP} \
  -profile=kubernetes \
  pki/clients/${SLAVES_HOSTNAMES[$i]}-csr.json | cfssljson -bare pki/clients/${SLAVES_HOSTNAMES[$i]}
done

#We will generate here the kube-controller certificate
cat > pki/controller/kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "${TLS_C}",
      "L": "${TLS_L}",
      "O": "system:kube-controller-manager",
      "OU": "${TLS_OU}",
      "ST": "${TLS_ST}"
    }
  ]
}
EOF

cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -profile=kubernetes \
  pki/controller/kube-controller-manager-csr.json | cfssljson -bare pki/controller/kube-controller-manager

#Now onto the generation of the proxy cert

cat > pki/proxy/kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "${TLS_C}",
      "L": "${TLS_L}",
      "O": "system:kube-proxy",
      "OU": "${TLS_OU}",
      "ST": "${TLS_ST}"
    }
  ]
}
EOF

cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -profile=kubernetes \
  pki/proxy/kube-proxy-csr.json | cfssljson -bare pki/proxy/kube-proxy


#Generation of the scheduler certificat
cat > pki/scheduler/kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "${TLS_C}",
      "L": "${TLS_L}",
      "O": "system:kube-scheduler",
      "OU": "${TLS_OU}",
      "ST": "${TLS_ST}"
    }
  ]
}
EOF

cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -profile=kubernetes \
  pki/scheduler/kube-scheduler-csr.json | cfssljson -bare pki/scheduler/kube-scheduler

#Generation of the API endpoint certificate
cat > pki/api/kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "${TLS_C}",
      "L": "${TLS_L}",
      "O": "kubernetes",
      "OU": "${TLS_OU}",
      "ST": "${TLS_ST}"
    }
  ]
}
EOF

cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -hostname=10.32.0.1,10.98.0.100,10.98.0.101,10.98.0.102,10.98.0.103,127.0.0.1,kubernetes.default \
  -profile=kubernetes \
  pki/api/kubernetes-csr.json | cfssljson -bare pki/api/kubernetes

# Service-Account cert and key

cat > pki/service-account/service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "${TLS_C}",
      "L": "${TLS_L}",
      "O": "kubernetes",
      "OU": "${TLS_OU}",
      "ST": "${TLS_ST}"
    }
  ]
}
EOF

cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -profile=kubernetes \
  pki/service-account/service-account-csr.json | cfssljson -bare pki/service-account/service-account

```

#### 2.5 Deploy the certificates

We will now generate a PKI infrastructure , and create all the certificate for
the kubernetes cluster.

```ansible-playbook -i inventory/hosts.yml -u root -k deploiement.yaml```

If you want to deploy them by hand , you can do it with the scp command :
```bash

for instance in slave01 slave02 slave03; do
  scp pki/ca/ca.pem pki/clients/${instance}-key.pem pki/clients/${instance}.pem ${instance}:~/
done

for instance in master01 master02 master03; do
  scp pki/ca/ca.pem pki/ca/ca-key.pem pki/api/kubernetes-key.pem pki/api/kubernetes.pem pki/service-account/service-account-key.pem pki/service-account/service-account.pem ${instance}:~/
done
```

#### 2.6 Encryption key

##### 2.6.1 What is an Encryption key

kubernetes support Data Encryption at rest , this mean that all secret managed by K8s , will be encrypted and not written in plain text.

This feature , is more than needed , but in orderd to encrypt Data At rest , K8s  will need an encryption Key.

We will generate the Encryption key as below:

```bash
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

cat > encryption-config.yaml << EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

```

Once this is done , You can use the ansible Playbook to deply the encryption key , or secure copy the encryption key on the master node:

```bash
scp ./encryption-config.yaml master01
scp ./encryption-config.yaml master02
scp ./encryption-config.yaml master03

```
