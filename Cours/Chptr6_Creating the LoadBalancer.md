### 6 Configuration of the LoadBalancer

#### 6.1 Why a Load Balancer

If you read another Kubernetes the Hard way on a Cloud provider guide , you are probalby wondering why are we doing this course.

Well on a Cloud Provider Creating a Load Balancing is fairly easy ,and most of the time is done via a couple of command.

But in our case , on premise , that is not that easy and we need to created our Loadbalancer server.

But rejoice yourself , you might learn a Thing or Two in the process.


#### 6.2 HaProxy LoadBalancer
I will use HaProxy , but you can use whatever LoadBalancer you like.

First install the package , and create a Backup of the original configuration file.
```bash
apt-get install haproxy

cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg_backup
```
Then we copy our configuration , adapt the adress to you master nodes:

```bash
cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
frontend apiservers
        bind *:6443
        mode tcp
        option  tcplog
        option forwardfor
        default_backend k8s_apiservers

frontend ingress
        bind *:443
        mode tcp
        option  tcplog
        option forwardfor
        default_backend k8s_ingress

backend k8s_apiservers
        mode tcp
        option  tcplog
        option ssl-hello-chk
        option log-health-checks
        default-server inter 10s fall 2
        server master01 10.98.0.101:6443 check
        server master02 10.98.0.102:6443 check
        server master03 10.98.0.103:6443 check


backend k8s_ingress
        mode tcp
        option  tcplog
        option ssl-hello-chk
        option log-health-checks
        default-server inter 10s fall 2
        server master01 10.98.0.101:6443 check
        server master02 10.98.0.102:6443 check
        server master03 10.98.0.103:6443 check

EOF
```


Once this is done , enable and start the system , after that , we check that everything run smoothly.
```bash
systemctl enable haproxy
systemctl start haproxy

systemctl status haproxy
```

Try a curl to see if this work:
```bash
curl --cacert ca.pem https://10.98.0.100:6443/version
```
(you need to be in a folder with ca.pem in it to work)

***Note: If you can't connect , see if the OS has a activated Firewall , I disabled ufw (I am on Ubuntu server) for this to work***

#### 6.3 Nginx Loadbalancer

```bash
apt-get install -y nginx
systemctl enable nginx
mkdir -p /etc/nginx/tcpconf.d
vim /etc/nginx/nginx.conf
```
and add at the end:
```bash
include /etc/nginx/tcpconf.d/*;
```
Then create the LoadBalancer file:
```bash
cat << EOF | sudo tee /etc/nginx/tcpconf.d/kubernetes.conf
stream {
    upstream kubernetes {
        server 10.98.0.101:6443;
        server 10.98.0.102:6443;
        server 10.98.0.103:6443;
    }

    server {
        listen 6443;
        listen 443;
        proxy_pass kubernetes;
    }
}
EOF
```

Try a curl to see if this work:
```bash
curl --cacert ca.pem https://10.98.0.100:6443/version
```
(you need to be in a folder with ca.pem in it to work)

***Note: If you can't connect , see if the OS has a activated Firewall , I disabled ufw (I am on Ubuntu server) for this to work***
