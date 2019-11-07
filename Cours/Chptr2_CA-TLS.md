### 2 Provisioning the CA and Generating the TLS certificates

As the previous section , we are not going to deep dive into CA/TLS , I will provide here a basic understanding of the topic.

The basics will help us trougought this course , but I Higly recommend you to continue learning on this topic.

CA and certificates are used everywhere in IT nowadays , really understading how these work will be a huge help for you

#### 2.1 What are CA/TLS and why do we need them ?

In this section we are going to provide **identities** to our kubernetes services.

In IT an Identities is Provided by a CA , a **Certificate Identity**

This CA will be used to signe x.509 compliant **Certificate**.

These Certificate , will be used to confirme the identity of the entity tha hold it.

Here is a little explanation on how all of this work.


#### 2.2 CA/TLS in a Kubernetes cluster

#### 2.3 Generate the CA

We will create our own CA , you could also use .
#### 2.4 Generate the certificate

#### 2.5 Deploy the certificates

We will now generate a PKI infrastructure , and create all the certificate for
the kubernetes cluster.


```ansible-playbook -i inventory/hosts.yml -u root -k deploiement.yaml```
