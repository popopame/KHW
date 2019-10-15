#### 4.1  What is the Kubernetes Control Planes? How does it work?

#### 4.2 Download the files

**NOTE: As usual , all commands must be done on all 3 clusters**


First , we need to download  the binaries needed for the Chapter , once downloaded , put them in the ```/usr/bin``` folder , so we can execute them.

```bash
mkdir -p /etc/kubernetes/config

wget --secure-protocol=auto\
  "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubectl"

  chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl

  mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/bin/


```
___
**In the 4.4 , 4.4 & 4.5 chapter , we will configure the the service file for each kubebernetes components , as for the etcd one be *very* carefull of the syntax**
___


#### 4.3 Configuring the API server

First we create a folder that we will use in the following chapter , and we copy the certificates needed in it.

Don't forger to re-type the following command if you restarted your server between the Chapter 3 and 4.

```bash
INTERNAL_IP=$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')
 ```
Then :

```bash
mkdir -p /var/lib/kubernetes/

cp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem \
    encryption-config.yaml /var/lib/kubernetes/

```

After that , we can cat this input into the service file.
Don't forget to modify the ```--etcd-servers=``` server line , to correspond to yours.
For me , the etcd adresse is : ```10.98.0.16,10.98.0.17.10.98.0.18```
```bash
cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes[Service]
ExecStart=/usr/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=Initializers,NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --enable-swagger-ui=true \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://10.98.0.16:2379,https://10.98.0.17:2379,https://192.168.0.18:2379 \\
  --event-ttl=1h \\
  --experimental-encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config=api/all \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5[Install]
WantedBy=multi-user.target
EOF

```

#### 4.4 Configuring the Kubernetes Controller Manager

Before creating the service file , copy the kubeconfig file into the lib folder

```bash
cp /kube-controller-manager.kubeconfig /var/lib/kubernetes/
```

The we can configure the service file

```bash
cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes[Service]
ExecStart=/usr/bin/kube-controller-manager \\
  --bind-address=0.0.0.0 \\
  --cluster-cidr=10.200.0.0/16 \\
  --allocate-node-cidrs=true \\
  --node-cidr-mask-size=24 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --cert-dir=/var/lib/kubernetes \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5[Install]
WantedBy=multi-user.target
EOF
```

#### 4.5 Configuring the Kubernetes scheduler

Same as above , move the kubeconfig file :
```bash
cp /kube-scheduler.kubeconfig /var/lib/kubernetes/
```

But after that , create a yaml file name kube-scheduler.yaml .
```bash
cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: kubescheduler.config.k8s.io/v1alpha1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF
```

After that , create the service file
```bash
cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```



##### Pray , Enable and Start !

Reload the daemon and start all the services.
If it doesn't work , you can use the commands I gave to you in the ETCD chapter
```bash
sudo systemctl daemon-reload
sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
```
#### 4.6 Enabling HTTP Health Check

The Load Balancer will do Health Check on our instances , they will be done on the port 6443.
Since we are not exposing that port , we will create a proxy to expose it.
We will use Nginx (but you can use whatever solution you want)

First we will install it , after that , we are going to delete the default config file , so that we can set our own.

```bash
yum -y install  nginx

cat > kubernetes.default.svc.cluster.local <<EOF
server {
  listen      80;
  server_name kubernetes.default.svc.cluster.local;location /healthz {
     proxy_pass                    https://127.0.0.1:6443/healthz;
     proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
  }
}
EOF
```

Then , we take care of the default configuration file.
```bash
rm /etc/nginx/sites-enabled/default

mv kubernetes.default.svc.cluster.local /etc/nginx/sites-available/kubernetes.default.svc.cluster.local

ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/sudo

systemctl restart nginx
systemctl enable nginx
```




#### 4.7 RBAC
