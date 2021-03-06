### 4 ETCD

#### 4.1 What is ETCD

ETCD is a Distributed Key-Value Data-Store.
Wich mean that it is , in its core a Database , but a Database that is intended to be deployed and accessed on a distributed system.
Understand a System that is deployed on more than one host.

The Database host Key-Value data (example foo: bar)

So , etcd provide a way to store data on a cluster of machine and make sure that the data is synchronized on all member of the cluster.

It's as simple as that !
#### 4.2 ETCD in Kubernetes

Since Kubernetes is by design a Distributed System (It can be ran on multiple servers.)
It needs a Distributed Database , that's were ETCD storm into the battle

Kubernetes uses etcd as a key-value database store. It stores the configuration of the Kubernetes cluster in etcd.

It also stores the actual state of the system and the desired state of the system in etcd.

It then uses etcd’s watch functionality to monitor changes to either of these two things. If they diverge, Kubernetes makes changes to reconcile the actual state and the desired state.
**PENSER A METTRE CSHEMA**

#### 4.3 What we will do in this Chapter

We will download the etcd binaries from the Official github.

After moving the etcd to the right directory , we will move the certificates to a directory to a folder that the binary can access.

And , to finish , we will create the service file that will be executed when you launch the etcd program.

#### 4.4 Configuring etcd on Master nodes

**All Commands bellow , unless specified otherwise , must be executed on all master nodes**
*I recomend using tmux for this*

First we will download and install the etcd program on the server.
Unpack it and move it on the bin folder , so that we can call him with the CLI

```bash
wget -q --show-progress --https-only --timestamping "https://github.com/etcd-io/etcd/releases/download/v3.4.2/etcd-v3.4.2-linux-amd64.tar.gz"

tar -xvf etcd-v3.3.9-linux-amd64.tar.gz
sudo mv etcd-v3.3.9-linux-amd64/etcd* /usr/local/bin/

```

Copy the certificate on the etcd lib folder:

```bash
mkdir -p /etc/etcd /var/lib/etcd
cp /ca.pem /kubernetes-key.pem /kubernetes.pem /etc/etcd/
```
Once this is done , we create a file named ```etcd.service```.
In this we will put all our configuration.

First , create two environement variables needed for this file:

**Note :Modify the ens18 by the network card name**

```bash
INTERNAL_IP=$(ip addr show ens18 | grep -Po 'inet \K[\d.]+') #THIS controller's internal IP
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
ExecStart=/usr/local/bin/etcd \\
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
  --initial-cluster master01=https://10.98.0.101:2380,master02=https://10.98.0.102:2380,master03=https://10.98.0.103:2380 \\
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
1748aef7d885aa5e, started, master03, https://10.98.0.18:2380, https://10.98.0.103:2379
aaaab241db54789c, started, master02, https://10.98.0.17:2380, https://10.98.0.102:2379
e15ab1211a4b4e4e, started, master01, https://10.98.0.16:2380, https://10.98.0.101:2379
```



___
**It doesn't Start/Don't work/I have a Bug: What to do**

If you have a bug , you should look for these:

* Error in the etcd.service file : typos in names or file path
* Error in the certificate file: look if the IP you autorized correspond to the ones you are using
* If all the files are were they should

If you have an error , it probably comes from a typo in your file.
You can see the logs of etcd(or any system related logs that might help you) by tiping one of these following commands:
* ```bash tail /var/log/messages ``` : will display the last line of the system log
* ```bash journalctl etcd -u etcd ``` : Will display the logs of etcd services
* ```bash systemctl status etcd ``` : Will display the status of the etcd service , as well a the last log line of the service

If you still struggle , don't hesite to ask me , or anyone on the web , the Open-Source Community is full of good-hearted people !
