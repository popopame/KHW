#Declaration of the Variables needed in this script , you need to modify these so that they correspond to your infrastrucre

declare -a SLAVES_IPS=("10.98.0.104" "10.98.0.105" "10.98.0.106")
declare -a SLAVES_HOSTNAMES=("slave01" "slave02" "slave03")
KUBERNETES_PUBLIC_IP=("10.98.0.100")


#Create a folder to put the configuration file , run this script in the KHW folder
mkdir configs
mkdir -p configs/{admin,clients,controller,proxy,scheduler,encrypt}
#Generate the Kubeconfig file for each slave node

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
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
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


#Generation of the Encryption config file
#To generate the encryption key , we take a random string of 32 characters

echo Creattion of the encrytpion file

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

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
