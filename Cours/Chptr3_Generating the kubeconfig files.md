### 3 Generating the kubeconfig files

#### 3.1 What is a kubeconfig file

This sections will be very simple :
**PENSER A METTRE CSHEMA**
A kubeconfig file , is the file that contain some configurations that will be applied on the cluster.

They can be used to apply changes/configration to a components of the cluster.
Or just apply changes to an user or changes policies.

***I also gave you a bash script that will generate all the kubeconfig file . I recommand to do all the config gile by hand at least one time.
So you can better understand how this work and what we will do , but if you decide to start over , you can use the script.***

#### 3.5 What we will do in this Chapter

We will generate the kubeconfig that will be used to configure the components

#### 3.4 Configuring etcd on Master nodes

First wer declare the variables that we will use (adapt these to your nodes)
```bash
declare -a SLAVES_IPS=("10.98.0.104" "10.98.0.105" "10.98.0.106")
declare -a SLAVES_HOSTNAMES=("slave01" "slave02" "slave03")
KUBERNETES_PUBLIC_IP=("10.98.0.100")

```

Then create the folder that we will use:
```bash
mkdir configs
mkdir -p configs/{admin,clients,controller,proxy,scheduler,encrypt}
```
finally we create all the kubeconfig file , for each components

```bash

for instance in ${SLAVES_HOSTNAMES[@]}; do
  echo Creation of the Kubeconfig for ${instance}

  kubectl config set-cluster KHW-cluster \
    --certificate-authority=pki/ca/ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_IP}:6443 \
    --kubeconfig=configs/clients/${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=pki/clients/${instance}.pem \
    --client-key=pki/clients/${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=configs/clients/${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=KHW-cluster \
    --user=system:node:${instance} \
    --kubeconfig=configs/clients/${instance}.kubeconfig

  kubectl config use-context default --kubeconfig=configs/clients/${instance}.kubeconfig

done


#Generating the Kubeconfig  file for the kube-proxy
echo Genetaring kube-proxy Kubeconfig

kubectl config set-cluster KHW-cluster \
  --certificate-authority=pki/ca/ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_IP}:6443 \
  --kubeconfig=configs/proxy/kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
  --client-certificate=pki/proxy/kube-proxy.pem \
  --client-key=pki/proxy/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=configs/proxy/kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=KHW-cluster \
  --user=system:kube-proxy \
  --kubeconfig=configs/proxy/kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=configs/proxy/kube-proxy.kubeconfig

#Generating kube-controller-manager Kubeconfig
echo Generating controller kubeconfig

kubectl config set-cluster KHW-cluster \
  --certificate-authority=pki/ca/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=configs/controller/kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=pki/controller/kube-controller-manager.pem \
  --client-key=pki/controller/kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=configs/controller/kube-controller-manager.kubeconfig

kubectl config set-context default \
  --cluster=KHW-cluster \
  --user=system:kube-controller-manager \
  --kubeconfig=configs/controller/kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=configs/controller/kube-controller-manager.kubeconfig

#Generating kube-sheduler kubeconfig

echo Generating kube-scheduler kubeconfig

kubectl config set-cluster KHW-cluster \
  --certificate-authority=pki/ca/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=configs/scheduler/kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=pki/scheduler/kube-scheduler.pem \
  --client-key=pki/scheduler/kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=configs/scheduler/kube-scheduler.kubeconfig

kubectl config set-context default \
  --cluster=KHW-cluster \
  --user=system:kube-scheduler \
  --kubeconfig=configs/scheduler/kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=configs/scheduler/kube-scheduler.kubeconfig

#Generating the admin kubeconfig
echo generating admin kubeconfig

kubectl config set-cluster KHW-cluster \
  --certificate-authority=pki/ca/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=configs/admin/admin.kubeconfig

kubectl config set-credentials admin \
  --client-certificate=pki/admin/admin.pem \
  --client-key=pki/admin/admin-key.pem \
  --embed-certs=true \
  --kubeconfig=configs/admin/admin.kubeconfig

kubectl config set-context default \
  --cluster=KHW-cluster\
  --user=admin \
  --kubeconfig=configs/admin/admin.kubeconfig

kubectl config use-context default --kubeconfig=configs/admin/admin.kubeconfig


```


Finally we need to generarte the encryption file , wich is a file containing a random string.
It will be used to encrypt data that will be encrypted at rest.

To obtain a randomstring we will use the following command:
```bash

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

```
We then use the varable we just created on a config file. (wich is not a Kubeconfig but a Yaml file)

```bash


cat > configs/encrypt/encryption-config.yaml <<EOF
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
