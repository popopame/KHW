### Configure the Network on the Slaves Machines

#### 9.1 What are we going to do

In this part we are going to configure the network on our Kubernetes cluster.
Since the network model of a Kubernetes Cluster can be a tricky thing to approach , I am first going to explain it.

#### 9.2 Networking Model of Kubernetes

The networking of a K8s cluster is straightforward: Each node gets one IP , and use it to communicate with other node.

The tricky part , is networking INSIDE a Kubernetes Cluster.
We already explained this part ine the Chapter 7.

In K8s , each pods get an IP address , an IP that is part of the K8s subnet.
In every Cluster there is at last one network Inside the cluster.

To implement this, they are numbers of way available on the net.
Feel free to read the official list here:https://kubernetes.io/docs/concepts/cluster-administration/networking/

We are going to use Weave in this Course.
Off course , you need to chose a Network provider that suits your needs : What OSI level do you need ? On what plateform are you deploying K8s? Do you need special protocol ? Do you need fine grained security ? ect...

Since the network in inside the cluster , we are also going to deploy a DNS inside our Cluster !

#### 9.3 Installing Weave

We are going to install Weave.
Network Manager in Kubernetes are generally deployments , wich mean we are going to apply a yaml wich will define the Pods that need to be launched.

***The command bellow need to be executed on all slave node***
First you need to activate IPV4 forwarding on all slaves nodes(You do not need to do this if you used the Ansible to deploy the Certificate):
```bash
sudo sysctl net.ipv4.conf.all.forwarding=1
echo "net.ipv4.conf.all.forwarding=1" | sudo tee -a /etc/sysctl.conf
```

The following commands can be executed via kubectl on the bastion hosts
***If you used a range different than 10.200.0.0/16 modify it in the following command***

```bash
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&env.IPALLOC_RANGE=10.200.0.0/16"
```
Then get the pods to see if they are running:
```bash
kubectl get pods -n kube-system

#You should have an output like the following
NAME              READY     STATUS    RESTARTS   AGE
weave-net-m69xq   2/2       Running   0          11s
weave-net-vmb2n   2/2       Running   0          11s
weave-net-pd3ds   2/2       Running   0          11s
```

If some or all pods are not deploying correctly use the ```kubectl describe -n kube-system <pod_name>``` command to gain some insight on what might be the problem.

#### 9.4 Testing weave

To test that the network can connect two pods correctly we are going to create a deployment of two nginx servers
```bash
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      run: nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 80
EOF
```
Next up , we expose the deployment on port 80 , and launch a BusyBox pods to curl our two Nginx pods

``bash
kubectl expose deployment/nginx

kubectl run busybox --image=radial/busyboxplus:curl --command -- sleep 3600
POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")
```
Then , if we get the ip of our  Nginx Pods:

```bash
kubectl get ep nginx
#You should have an output like this:
NAME      ENDPOINTS                       AGE
nginx     10.200.0.2:80,10.200.128.1:80   50m
```

Try to curl the Nginx IP from the BusyBox pods
```bash
kubectl exec $POD_NAME -- curl <first nginx pod IP address>
kubectl exec $POD_NAME -- curl <second nginx pod IP address>
```

If you do not have an error in return , that mean that the Network is UP and Running !

#### 9.5 Deploying a DNS

A DNS is not mandatory , but a good addition nonetheless.

We simply use the CoreDNS deployment from the Keysley HIGHTOWER Hard Ways's

```bash
kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns.yaml
```

check if this works

 ```bash
 kubectl run busybox --image=busybox:1.28 --command -- sleep 3600

 kubectl get pods -l run=busybox

 POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")

 kubectl exec -ti $POD_NAME -- nslookup kubernetes

 ##Results
 Server:    10.32.0.10
 Address 1: 10.32.0.10 kube-dns.kube-system.svc.cluster.local

 Name:      kubernetes
 Address 1: 10.32.0.1 kubernetes.default.svc.cluster.local
 ```
