#This bellw will generate the certificate Authority
#This  certificate will be used to create all the other certificate
mkdir -p pki/{admin,api,ca,clients,controller,proxy,scheduler,service-account}

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
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "FR",
      "L": "Neuilly-Plaisance",
      "O": "Kubernetes",
      "OU": "PopoKube",
      "ST": "popotown"
    }
  ]
}
EOF

#Below we will generate the Admin certificate
cfssl gencert -initca pki/ca/ca-csr.json | cfssljson -bare pki/ca/ca

cat > pki/admin/admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "FR",
      "L": "Neuilly-Plaisance",
      "O": "Kubernetes",
      "OU": "PopoKube",
      "ST": "popotown"
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


declare -a ips=("10.98.0.20" "10.98.0.21" "10.98.0.22")
declare -a hostnames=("slave01" "slave02" "slave03")
for i in {0..2}; do

  cat > pki/clients/${hostnames[$i]}-csr.json <<EOF
{
  "CN": "system:node:${hostnames[$i]}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "FR",
      "L": "Neuilly-Plaisance",
      "O": "system:kubelet",
      "OU": "PopoKube",
      "ST": "popotown"
    }
  ]
}
EOF

cfssl gencert \
  -ca=pki/caca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -hostname=${hostnames[$i]},${ips[$i]} \
  -profile=kubernetes \
  pki/clients/${hostnames[$i]}-csr.json | cfssljson -bare pki/clients/${hostnames[$i]}
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
      "C": "FR",
      "L": "Neuilly-Plaisance",
      "O": "system:kube-controller",
      "OU": "PopoKube",
      "ST": "popotown"
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
      "C": "FR",
      "L": "Neuilly-Plaisance",
      "O": "system:node-proxier",
      "OU": "PopoKube",
      "ST": "popotown"
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


#Generation of the scheduler certifcat
cat > pki/scheduler/kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "FR",
      "L": "Neuilly-Plaisance",
      "O": "system:kube-scheduler",
      "OU": "PopoKube",
      "ST": "popotown"
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
      "C": "FR",
      "L": "Neuilly-Plaisance",
      "O": "system:API-endpoint",
      "OU": "PopoKube",
      "ST": "popotown"
    }
  ]
}
EOF

cfssl gencert \
  -ca=pki/ca/ca.pem \
  -ca-key=pki/ca/ca-key.pem \
  -config=pki/ca/ca-config.json \
  -hostname=10.32.0.1,10.98.0.20,10.98.0.21,10.98.0.22,127.0.0.1,kubernetes.default \
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
      "C": "FR",
      "L": "Neuilly-Plaisance",
      "O": "system:API-endpoint",
      "OU": "PopoKube",
      "ST": "popotown"
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
