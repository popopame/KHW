 ### 7 Configuring the Worker Nodes

#### 7.1 What is a Kubernetes Worker NODE

A Kubernetes Worker node are responsible of the "workload"
They will launch the container applications.

Theses nodes have the services necessary to run the apps and will be managed by the master node.

We are going to install theses components:
* **kubelet** Control each worker node , they will provide the API on wich the control plane  will interact
* **kube-proxy**: Will manage the network used by the pods
* **Container Runtinme** : This component will run the container

#### 7.2 What are we going to do in this course part

#### 7.3 Download the binaries

First download the binaries need on the worker node:
```bash
wget -q --show-progress --https-only --timestamping \
https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.15.0/crictl-v1.15.0-linux-amd64.tar.gz \
 https://github.com/opencontainers/runc/releases/download/v1.0.0-rc8/runc.amd64 \
 https://github.com/containernetworking/plugins/releases/download/v0.8.2/cni-plugins-linux-amd64-v0.8.2.tgz \
 https://github.com/containerd/containerd/releases/download/v1.2.9/containerd-1.2.9.linux-amd64.tar.gz \
 https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl \
 https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-proxy \
 https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubelet \
 https://storage.googleapis.com/kubernetes-the-hard-way/runsc-50c283b9f56bb7200938d9e207355f05f79f0d17

```

Then we create the directories:
```bash
sudo mkdir -p \
 /etc/cni/net.d \
 /opt/cni/bin \
 /var/lib/kubelet \
 /var/lib/kube-proxy \
 /var/lib/kubernetes \
 /var/run/kubernetes
```

And then , we make the binaries executable and move them ,where they are needed:
```bash
sudo mv runsc-50c283b9f56bb7200938d9e207355f05f79f0d17 runsc #In this line and the one below , we change the name of the binaries , for lisibility purpose
sudo mv runc.amd64 runc
chmod +x kubectl kube-proxy kubelet runc runsc
sudo mv kubectl kube-proxy kubelet runc runsc /usr/local/bin/
sudo tar -xvf crictl-v1.12.0-linux-amd64.tar.gz -C /usr/local/bin/
sudo tar -xvf cni-plugins-amd64-v0.6.0.tgz -C /opt/cni/bin/
sudo tar -xvf containerd-1.2.0-rc.0.linux-amd64.tar.gz -C /
```
***BE CAREFULL : The Kubelet won't start if Swap is enabled , you need to disable it***

To do so type go to you fstab file (located in /etc/fstab) and comment (add #) to the file containing the Swap word.


#### 7.4 CNI Networking

Now , here come a Tricky part , it's not hard , but the design could bug come people.

Below , we are going to define the CNI for the Container on THIS host (CNI stands for Common Network Interface).

So we are going to define a CIDR and a network FOR THIS ONE NODE. All pod on a Node will use this interface and CIDR , so every Slave/Worker Node will have a unique CIDR.
Here is a little picture to better explain ths:

So , since this is wrapped up , here is the CIDR we will use for each node:

```bash
slave01 = POD_CIDR=10.200.1.0/24
slave02 = POD_CIDR=10.200.2.0/24
slave03 = POD_CIDR=10.200.3.0/24
```
Declare this variable on the respective node , and then ,we can proceed;


##### CNI Config Files

Below we will define the CNI Config files.
CNI stand for Contener Network Interface , it will be used to give to every Container a virtual interface.
Define the CNI Bridge Network Config File.
```bash
cat <<EOF | sudo tee /etc/cni/net.d/10-bridge.conf
{
    "cniVersion": "0.3.1",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "${POD_CIDR}"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOF
```

and then , define the loopback config.
```bash
cat <<EOF | sudo tee /etc/cni/net.d/99-loopback.conf
{
    "cniVersion": "0.3.1",
    "type": "loopback"
}
EOF
```

#### 7.5 Container Runtime Setup

```bash
sudo mkdir -p /etc/containerd/
cat << EOF | sudo tee /etc/containerd/config.toml
[plugins]
  [plugins.cri.containerd]
    snapshotter = "overlayfs"
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runc"
      runtime_root = ""
    [plugins.cri.containerd.untrusted_workload_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runsc"
      runtime_root = "/run/containerd/runsc"
    [plugins.cri.containerd.gvisor]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runsc"
      runtime_root = "/run/containerd/runsc"
EOF
```

```bash
cat <<EOF | sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF
```

#### 7.6 Configuring Kubelet

```bash
sudo cp /${HOSTNAME}-key.pem /${HOSTNAME}.pem /var/lib/kubelet/

sudo cp /${HOSTNAME}.kubeconfig /var/lib/kubelet/kubeconfig

sudo cp /ca.pem /var/lib/kubernetes/
```

```bash
cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.32.0.10"
podCIDR: "${POD_CIDR}"
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${HOSTNAME}.pem"
tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME}-key.pem"
EOF
```

```bash
cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```
#### 7.7 Kube-Proxy Setup

```bash
sudo cp kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig

cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "10.200.0.0/16"
EOF


cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```


***Note You need to disable Swap before launching the Services.
To do this follow this instructions:***

You need to edit the fstab file and comment the swapp files
First vim your way into the fstab files

```
Vim /etc/fstab
```

then you need to comment the line that contain the swap word.

Once this is done you can enable and start the services.
