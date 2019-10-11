### 3 ETCD

#### 3.1 What is ETCD

#### 3.2 ETCD in Kubernetes


#### 3.3 Configuring etcd on Master nodes

**All Commands bellow , unless specified otherwise , must be executed on all master nodes**
*I recomend using tmux for this*

First we will download and install the etcd program on the server.
Unpack it and move it on the bin folder , so that we can call him with the CLI

```bash
wget --secure-protocol=auto "https://github.com/coreos/etcd/releases/download/v3.3.9/etcd-v3.3.9-linux-amd64.tar.gz"

tar -xvf etcd-v3.3.9-linux-amd64.tar.gz
sudo mv etcd-v3.3.9-linux-amd64/etcd* /usr/local/bin/

```

Once this is done , we create a file named ```etcd.service```.
In this we will put all our configuration.

First , create two environement variables needed for this file:

**Note :Modify the eth0 by the network card name**

```bash
INTERNAL_IP=$(ip addr show eth0 | grep -Po 'inet \K[\d.]+') #THIS controller's internal IP
ETCD_NAME=$(hostname -s)
```

Then , we parse the configuration:

**Note: Modify the "initial-cluster-controller" by the names of your masters**

```bash
cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos
[Service]
ExecStart=/usr/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster master01=https://10.98.0.16:2380,master02=https://10.98.0.17:2380,master03=https://10.98.0.18:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
```

After that , we need to reload the daemon so that the changes are used.
Then , we can enable the service at startup , and start the service.
```bash
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd
```
I recommend to to a ```systemctl status etcd``` to see if everything run smoothly


You can now test to see if your etcd cluster is working:

```bash
sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem
#You should have an output that look like This
1748aef7d885aa5e, started, master03, https://10.98.0.18:2380, https://10.98.0.18:2379
aaaab241db54789c, started, master02, https://10.98.0.17:2380, https://10.98.0.17:2379
e15ab1211a4b4e4e, started, master01, https://10.98.0.16:2380, https://10.98.0.16:2379
```




If you have a bug , you should look for these:

* Error in the etcd.service file : typos in names or file path
* Error in the certificate file: look if the IP you autorized correspond
* If all the files are were they should

If you still struggle , don't hesite to ask me , or anyone on the web , the Open-Source Community is full of good-hearted people !
