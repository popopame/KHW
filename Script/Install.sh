#Install the Packet
wget -q --show-progress --https-only --timestamping \
  https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/linux/cfssl \
  https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/linux/cfssljson \
  https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl

chmod +x cfssl cfssljson kubectl
#Be carefull ! Under Centos you must move them under /usr/bin
mv cfssl cfssljson kubectl /usr/local/bin
