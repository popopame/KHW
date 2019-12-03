### Configure the kubectl on the Bastion On for Distant Access

#### 8.1 Set the Variables

Go back on the Bastion host(on wich you generated the certificate) ,  we will configure the kubectl access.
We will use the admin profile.


***Note: If you rebooted your VM you need to re-declare the KUBERNETES_PUBLIC_ADRESS ****

```bash
kubectl config set-cluster KHW-cluster \
        --certificate-authority=pki/ca/ca.pem \
        --embed-certs=true \
        --server=https://10.98.0.100:6443 \
        --kubeconfig=configs/admin/admin-remote.kubeconfig


kubectl config set-credentials admin \
        --client-certificate=pki/admin/admin.pem \
        --client-key=pki/admin/admin-key.pem \
        --kubeconfig=configs/admin/admin-remote.kubeconfig

kubectl config set-context KHW-cluster \
        --cluster=KHW-cluster \
        --user=admin \
        --kubeconfig=configs/admin/admin-remote.kubeconfig

kubectl config use-context KHW-cluster --kubeconfig=configs/admin/admin-remote.kubeconfig
```
Then copy the file you juste created in the .kube folder of the user you are using.

```bash
cp configs/admin/admin-remote.kubeconfig ~/.kube/config
```

#### 8.2 Test the Kubectl

```bash
kubectl get componentstatuses
```

Once this is done , you can copy the file you just created on another server to access the cluster. (Be wary that the server must be able to ping the public IP of your cluster).
