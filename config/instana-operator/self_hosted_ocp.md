<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Self Hosted Instana backend on OpenShift](#self-hosted-instana-backend-on-openshift)
  - [1. Get a cluster from TechZon using the following link. I used 4 nodes (8 CPU, 32 GB) , 250 GB storage, and OpenShift version 4.8](#1-get-a-cluster-from-techzon-using-the-following-link-i-used-4-nodes-8-cpu-32-gb--250-gb-storage-and-openshift-version-48)
  - [2. Connect to your Bastion node:](#2-connect-to-your-bastion-node)
  - [3. Start by setting up OCS storage. I did it based on the tutorial available on GitHub page. Below you can find requied steps:](#3-start-by-setting-up-ocs-storage-i-did-it-based-on-the-tutorial-available-on-github-page-below-you-can-find-requied-steps)
  - [4. Change the port 9000 used by haproxy to e.g. 9111 as otherwise you will have conflict with **ClickHouse** database.](#4-change-the-port-9000-used-by-haproxy-to-eg-9111-as-otherwise-you-will-have-conflict-with-clickhouse-database)
  - [5. Install Instana Plugin. There is IBM documentation on that.](#5-install-instana-plugin-there-is-ibm-documentation-on-that)
  - [6. Setup Instana datastores](#6-setup-instana-datastores)
    - [6.0 Parparation](#60-parparation)
    - [6.1  Create Zookeeper datastore using Zookeeper Operaror](#61--create-zookeeper-datastore-using-zookeeper-operaror)
    - [6.2  Create Kafka datastore using Strimzi Operaror](#62--create-kafka-datastore-using-strimzi-operaror)
    - [6.3  Create Elasticsearch datastore using Elasticsearch (ECK) Operator](#63--create-elasticsearch-datastore-using-elasticsearch-eck-operator)
    - [6.4  Create CockroachDB datastore using CockroachDB Kubernetes Operator](#64--create-cockroachdb-datastore-using-cockroachdb-kubernetes-operator)
    - [6.5  Create Cassandra datastore using Cass Operaror](#65--create-cassandra-datastore-using-cass-operaror)
    - [6.6  Create Clickhouse datastore using ClickHouse Operator](#66--create-clickhouse-datastore-using-clickhouse-operator)
  - [7. Install Cert Manager](#7-install-cert-manager)
  - [8. Create namespace for Instana Operator and required secret. Please make sure to put your valid **DOWNLOAD_KEY**](#8-create-namespace-for-instana-operator-and-required-secret-please-make-sure-to-put-your-valid-download_key)
  - [9. Add required permissions for service account:](#9-add-required-permissions-for-service-account)
  - [10. Create a file called *values.yaml* in /tmp. This will tell Instana operator which secret to use to pull containers:](#10-create-a-file-called-valuesyaml-in-tmp-this-will-tell-instana-operator-which-secret-to-use-to-pull-containers)
  - [11. Install Instana Operator:](#11-install-instana-operator)
  - [12.  Check if it is running `kubectl get pods -n instana-operator`. You should see one pod running:](#12--check-if-it-is-running-kubectl-get-pods--n-instana-operator-you-should-see-one-pod-running)
  - [13. Create directories to hold yaml files of Instana Core:](#13-create-directories-to-hold-yaml-files-of-instana-core)
  - [14. Create two namespaces : *instana-core* , *instana-units*](#14-create-two-namespaces--instana-core--instana-units)
  - [15. Download Instana license. Please make sure to provide valid **SALES_KEY**](#15-download-instana-license-please-make-sure-to-provide-valid-sales_key)
  - [16. Create Diffie-Hellman parameters for **instana-base**  secret](#16-create-diffie-hellman-parameters-for-instana-base--secret)
  - [17. Create **instana-registry** secret in **instana-core** and **instana-units** namespaces. Of coure provide valid **DOWNLOAD_KEY**](#17-create-instana-registry-secret-in-instana-core-and-instana-units-namespaces-of-coure-provide-valid-download_key)
  - [18. Create combined key/cert file. Provide *passw0rd* as pass phrase :](#18-create-combined-keycert-file-provide-passw0rd-as-pass-phrase-)
  - [19. Create **Core** Secret.](#19-create-core-secret)
  - [20. Create **instana-tls** secret. Provide baseDomain as CN](#20-create-instana-tls-secret-provide-basedomain-as-cn)
  - [21. Create **Unit Secret**.](#21-create-unit-secret)
  - [22. Add required permissions for service accounts. Without those the pods will not start.](#22-add-required-permissions-for-service-accounts-without-those-the-pods-will-not-start)
  - [23. Create **spans-volume-claim** and **appdata-writer** persistent volume claims](#23-create-spans-volume-claim-and-appdata-writer-persistent-volume-claims)
  - [24. In */root/instana-template* there should be core.yaml file which needs to be updated as below for your environment.](#24-in-rootinstana-template-there-should-be-coreyaml-file-which-needs-to-be-updated-as-below-for-your-environment)
  - [25. Once the file is ready, please apply it `kubectl apply -f core.yaml`. You can check what is happening by looking at the events. Initially I found there information on permission issue causing pods' startup issues.](#25-once-the-file-is-ready-please-apply-it-kubectl-apply--f-coreyaml-you-can-check-what-is-happening-by-looking-at-the-events-initially-i-found-there-information-on-permission-issue-causing-pods-startup-issues)
  - [26. If you don't see any errors you should eventually see pods running when you type: `kubectl get pods -n instana-core`](#26-if-you-dont-see-any-errors-you-should-eventually-see-pods-running-when-you-type-kubectl-get-pods--n-instana-core)
  - [27. Populate the **unit.yaml** file as below.](#27-populate-the-unityaml-file-as-below)
  - [28. When done, apply your settings: `kubectl apply -f unit.yaml`](#28-when-done-apply-your-settings-kubectl-apply--f-unityaml)
  - [29. Progress can be monitored with `kubectl get events -n instana-units`](#29-progress-can-be-monitored-with-kubectl-get-events--n-instana-units)
  - [30. Once process completes, you should get pods running `kubectl get pods -n instana-units`. Example output:](#30-once-process-completes-you-should-get-pods-running-kubectl-get-pods--n-instana-units-example-output)
  - [31. Create a route for accessing the UI.](#31-create-a-route-for-accessing-the-ui)
  - [32. Create a route for agent acceptor](#32-create-a-route-for-agent-acceptor)
  - [33. Now you should be able to connect to your Instana by putting https://<your_hostname> in the browser](#33-now-you-should-be-able-to-connect-to-your-instana-by-putting-httpsyour_hostname-in-the-browser)
  - [34. If something is missing or not right in this tuotorial, please let me know.](#34-if-something-is-missing-or-not-right-in-this-tuotorial-please-let-me-know)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Self Hosted Instana backend on OpenShift 

Even Instana on OpenShift is not officially supported, it can be installed on Fyre OCP+ clusters available in TechZone.  I will list the steps
required to install Instana backend. Those are based on [IBM Documentation](https://www.ibm.com/docs/en/obi/current?topic=kubernetes-installing-operator-based-instana-setup)  describing setup of Instana on Kubernetes


## 1. Get a cluster from TechZon using the [following link](https://techzone.ibm.com/collection/fyre-ocp-clusters). I used 4 nodes (8 CPU, 32 GB) , 250 GB storage, and OpenShift version 4.8

## 2. Connect to your Bastion node:
```
ssh -i  ssh_private_key.pem root@<IP_PROVIDED_BY_TECHZONE>
```
## 3. Start by setting up OCS storage. I did it based on the tutorial available on [GitHub page](https://github.ibm.com/icp4d-sre/sre-infra/blob/master/How-to-install-OCS-(Openshift-Container-Storage)-4.8-on-OpenShift-4.8-FYRE.md). Below you can find requied steps:  
   - Install **Local Storage Operator** in Operator Hub of OpenShift console
   - Connect to your Bastion node:
   ```
   ssh -i  ssh_private_key.pem root@<IP_PROVIDED_BY_TECHZONE>
   ```
   - Check if was installed correctly. Commands can be executed easily from Bastion node (IP, username, ssh key is provided in the e-mail from Technology Zone)
   ```
   oc get po -n openshift-local-storage
   ```
   - Install **Openshift Container Storage** for OCP 4.8 or pervious version, **Openshift Data Foundation** for OCP 4.10 version in Operator Hub of OpenShift console
   - Check if it was installed correctly
   ```
   oc get po -n openshift-storage
   ```
   - Label 3 worker nodes to be used by OCS. Of course names will differ in your instance
   ```
   oc get node -o name -l node-role.kubernetes.io/worker | sed 's/node\///'
   oc label node worker0.itzocp-665001jbi0-j816ol8l.cp.fyre.ibm.com cluster.ocs.openshift.io/openshift-storage='' --overwrite
   oc label node worker1.itzocp-665001jbi0-j816ol8l.cp.fyre.ibm.com cluster.ocs.openshift.io/openshift-storage='' --overwrite
   oc label node worker2.itzocp-665001jbi0-j816ol8l.cp.fyre.ibm.com cluster.ocs.openshift.io/openshift-storage='' --overwrite
   ```
   - Check disks on Worker nodes. Make sure you see 250GB as /dev/vdb. Otherwise adjust the command below.
   ```
   ssh core@worker0.itzocp-665001jbi0-j816ol8l.cp.fyre.ibm.com
   lsblk -l
   ```
   - Create Local Volume (from Bastion Host):
   ```
   ssh -i ssh_private_key.pem root@<IP_PROVIDED_BY_TECHZONE>
   oc apply -f - << EOF
   apiVersion: "local.storage.openshift.io/v1"
   kind: "LocalVolume"
   metadata:
     name: "local-disks"
     namespace: "openshift-local-storage"
   spec:
     nodeSelector:
       nodeSelectorTerms:
       - matchExpressions:
           - key: cluster.ocs.openshift.io/openshift-storage
             operator: In
             values:
             - ""
     storageClassDevices:
       - storageClassName: "localblock-sc"
         volumeMode: Block
         devicePaths:
           - /dev/vdb
   EOF
   ```
   - Check if  all went well. Storage class **localblock-sc** should be created 
   ```
   oc get all -n openshift-local-storage
   oc get pv -l storage.openshift.com/local-volume-owner-name=local-disks
   oc get sc
   ```
   - Create Storage Cluster instance in Installed Operators - **Openshift Container Storage** or **Openshift Data Foundation**. Make sure to change 
   mode to **Internal - Attached Devices** which will allow you to see **localblock-sc** storage class created previously
   - Verify if everything created correctly. Pods should be running and storage classes named like *ocs-* should be created:
   ```
   oc get po -n openshift-storage
   oc get sc
   ```
   - Set ocs-storagecluster-cephfs StorageClass as default StorageClass
   ```
   kubectl patch storageclass ocs-storagecluster-cephfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
   
   #kubectl get sc
   NAME                                  PROVISIONER                             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
   localblock-sc                         kubernetes.io/no-provisioner            Delete          WaitForFirstConsumer   false                  176m
   ocs-storagecluster-ceph-rbd           openshift-storage.rbd.csi.ceph.com      Delete          Immediate              true                   85m
   ocs-storagecluster-ceph-rgw           openshift-storage.ceph.rook.io/bucket   Delete          Immediate              false                  88m
   ocs-storagecluster-cephfs (default)   openshift-storage.cephfs.csi.ceph.com   Delete          Immediate              true                   85m
   openshift-storage.noobaa.io           openshift-storage.noobaa.io/obc         Delete          Immediate              false                  83m

   ```
## 4. Change the port 9000 used by haproxy to e.g. 9111 as otherwise you will have conflict with **ClickHouse** database. 
```
vi /etc/haproxy/haproxy.cfg
systemctl stop haproxy
systemctl start haproxy
```

## 5. Install Instana Plugin. There is [IBM documentation](https://www.ibm.com/docs/en/obi/current?topic=kubernetes-instana-kubectl-plug-in) on that.   
   **Option A**: I have already copied the installation file **kubectl-instana-linux_amd64-release-223-0.tar.gz** to Basion Node
      ```
      mkdir kubectl-instana; cd kubectl-instana
      tar -xvf /tmp/kubectl-instana-linux_amd64-release-223-0.tar.gz 
      export PATH=$PATH:/root/kubectl-instana
      kubectl instana --version
      ```
   **Option B**:  
      ```
      cat > /etc/yum.repos.d/Instana-Product.repo << EOF
      [instana-product]
      name=Instana-Product
      baseurl=https://self-hosted.instana.io/rpm/release/product/rpm/generic/x86_64/Packages
      enabled=1
      gpgcheck=1
      repo_gpgcheck=1
      gpgkey=https://self-hosted.instana.io/signing_key.gpg
      priority=5
      sslverify=1
      #proxy=http://x.x.x.x:8080
      #proxy_username=
      #proxy_password=
      EOF

      yum makecache -y --timer
      yum install -y instana-kubectl
      ```
## 6. Setup Instana datastores  
   Install instana datastores using **3-rd party vender operators**  
   
### 6.0 Parparation  

```sh
# Install helm3, see https://github.com/helm/helm#install
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
# Unzip the manifests for 3-party vender operators
tar zxvf onprem-distkit.tgz  // onprem-distkit.tgz is in packages directory
cd onprem-distkit

```  
### 6.1  [Create Zookeeper datastore using Zookeeper Operaror](https://github.ibm.com/instana/lab-self-hosting-k8s/tree/main/onprem-distkit/zookeeper/operator)
```sh
# Zookeeper Operator installation
helm repo add pravega https://charts.pravega.io
helm repo update
helm install instana -n instana-clickhouse-zookeeper --create-namespace pravega/zookeeper-operator
# Ensemble deployment
kubectl apply -f zookeeper/operator/manifests/instana-zookeeper.yaml -n instana-clickhouse-zookeeper
# Deployment verification
kubectl get all -n instana-clickhouse-zookeeper
NAME                                             READY   STATUS    RESTARTS   AGE
pod/instana-zookeeper-operator-df5c8df87-6ql26   1/1     Running   0          4h37m
pod/instana-0                                    1/1     Running   0          3h22m
pod/instana-1                                    1/1     Running   0          3h22m
pod/instana-2                                    1/1     Running   0          3h21m

NAME                           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                                        AGE
service/instana-client         ClusterIP   10.43.224.156   <none>        2181/TCP                                       3h22m
service/instana-headless       ClusterIP   None            <none>        2181/TCP,2888/TCP,3888/TCP,7000/TCP,8080/TCP   3h22m
service/instana-admin-server   ClusterIP   10.43.158.156   <none>        8080/TCP                                       3h22m

NAME                                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/instana-zookeeper-operator   1/1     1            1           4h37m

NAME                                                   DESIRED   CURRENT   READY   AGE
replicaset.apps/instana-zookeeper-operator-df5c8df87   1         1         1       4h37m

NAME                       READY   AGE
statefulset.apps/instana   3/3     3h22m
```
    
###   6.2  [Create Kafka datastore using Strimzi Operaror](https://github.ibm.com/instana/lab-self-hosting-k8s/blob/main/onprem-distkit/kafka/operator/README.md)  
```sh
# Strimzi Operator installation
helm repo add strimzi https://strimzi.io/charts/
helm repo update
helm install strimzi strimzi/strimzi-kafka-operator --version 0.28.0 -n instana-kafka --create-namespace
# Ensemble deployment
kubectl apply -f kafka/operator/manifests/instana-kafka.yaml -n instana-kafka
kubectl wait kafka/instana --for=condition=Ready --timeout=300s -n instana-kafka
# Deployment verification
kubectl get pods -n instana-kafka
NAME                                        READY   STATUS    RESTARTS   AGE
strimzi-cluster-operator-7695cb5f7f-b6ffn   1/1     Running   0          6h24m
instana-zookeeper-1                         1/1     Running   0          47m
instana-zookeeper-2                         1/1     Running   0          47m
instana-zookeeper-0                         1/1     Running   0          47m
instana-kafka-1                             1/1     Running   0          46m
instana-kafka-0                             1/1     Running   0          46m
instana-kafka-2                             1/1     Running   0          46m
```
      
### 6.3  [Create Elasticsearch datastore using Elasticsearch (ECK) Operator](https://github.ibm.com/instana/lab-self-hosting-k8s/blob/main/onprem-distkit/elasticsearch/operator/README.md)  
 ```sh
# Elasticsearch (ECK) Operator installation
helm repo add elastic https://helm.elastic.co
helm repo update
helm install elastic-operator elastic/eck-operator -n instana-elastic --create-namespace
# Ensemble deployment
kubectl apply -f elasticsearch/operator/manifests/instana-elasticsearch.yaml -n instana-elastic
# Deployment verification
kubectl get all -n instana-elastic
NAME                       READY   STATUS    RESTARTS   AGE
pod/elastic-operator-0     1/1     Running   1          4m14s
pod/instana-es-default-1   1/1     Running   0          2m42s
pod/instana-es-default-0   1/1     Running   0          2m42s
pod/instana-es-default-2   1/1     Running   0          2m42s

NAME                               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/elastic-operator-webhook   ClusterIP   10.43.212.82    <none>        443/TCP    4m14s
service/instana-es-transport       ClusterIP   None            <none>        9300/TCP   2m44s
service/instana-es-http            ClusterIP   10.43.204.194   <none>        9200/TCP   2m44s
service/instana-es-default         ClusterIP   None            <none>        9200/TCP   2m42s

NAME                                  READY   AGE
statefulset.apps/elastic-operator     1/1     4m14s
statefulset.apps/instana-es-default   3/3     2m42s
 ```
      
### 6.4  [Create CockroachDB datastore using CockroachDB Kubernetes Operator](https://github.ibm.com/instana/lab-self-hosting-k8s/blob/main/onprem-distkit/cockroachdb/operator/README.md)  
```sh
# CockroachDB Kubernetes Operator installation
kubectl apply -f https://raw.githubusercontent.com/cockroachdb/cockroach-operator/master/install/crds.yaml
curl https://raw.githubusercontent.com/cockroachdb/cockroach-operator/master/install/operator.yaml | sed 's|cockroach-operator-system|instana-cockroachdb|g' | kubectl apply -f -
# Ensemble deployment
kubectl apply -f cockroachdb/operator/manifests/instana-cockroachdb.yaml -n instana-cockroachdb
# Deployment verification
kubectl get pods -n instana-cockroachdb
NAME                                  READY   STATUS    RESTARTS   AGE
cockroach-operator-6f7b86ffc4-9t9zb   1/1     Running   0          3m22s
cockroachdb-0                         1/1     Running   0          2m31s
cockroachdb-1                         1/1     Running   0          102s
cockroachdb-2                         1/1     Running   0          46s
```
      
### 6.5  [Create Cassandra datastore using Cass Operaror](https://github.ibm.com/instana/lab-self-hosting-k8s/blob/main/onprem-distkit/cassandra/operator/README.md)  
```sh
# Cass Operator installation
helm repo add k8ssandra https://helm.k8ssandra.io/stable
helm repo update
helm install cass-operator k8ssandra/cass-operator -n instana-cassandra --create-namespace
# Security settings
kubectl apply -f cassandra/operator/manifests/cassandra_scc.yaml
# Ensemble deployment
kubectl apply -f cassandra/operator/manifests/instana-cassandra.yaml -n instana-cassandra
# Deployment verification
$ kubectl get pods -n instana-cassandra --selector cassandra.datastax.com/cluster=instana
NAME                            READY   STATUS    RESTARTS   AGE
instana-cassandra-default-sts-1   2/2     Running   0          5m10s
instana-cassandra-default-sts-2   2/2     Running   0          5m10s
instana-cassandra-default-sts-0   2/2     Running   0          5m10s
   
```
      
### 6.6  [Create Clickhouse datastore using ClickHouse Operator](https://github.ibm.com/instana/lab-self-hosting-k8s/blob/main/onprem-distkit/clickhouse/operator/README.md)  
```sh
# Clickhouse Operator installation
curl -s https://raw.githubusercontent.com/Altinity/clickhouse-operator/master/deploy/operator-web-installer/clickhouse-operator-install.sh | OPERATOR_NAMESPACE=instana-clickhouse bash
# Ensemble deployment
kubectl apply -f clickhouse/operator/manifests/instana-clickhouse.yaml -n instana-clickhouse
# Deployment verification
$ kubectl get all -n instana-clickhouse
NAME                                       READY   STATUS    RESTARTS   AGE
pod/clickhouse-operator-6fd75cbd68-lnd2n   2/2     Running   0          170m
pod/svclb-clickhouse-instana-qv8c6         2/2     Running   0          158m
pod/chi-instana-local-0-0-0                2/2     Running   0          158m
pod/chi-instana-local-0-1-0                2/2     Running   0          134m

NAME                                  TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                         AGE
service/clickhouse-operator-metrics   ClusterIP      10.43.114.134   <none>        8888/TCP                        170m
service/clickhouse-instana            LoadBalancer   10.43.184.83    9.46.95.158   8123:30458/TCP,9000:31584/TCP   158m
service/chi-instana-local-0-0         ClusterIP      None            <none>        8123/TCP,9000/TCP,9009/TCP      158m
service/chi-instana-local-0-1         ClusterIP      None            <none>        8123/TCP,9000/TCP,9009/TCP      134m

NAME                                      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/svclb-clickhouse-instana   1         1         1       1            1           <none>          158m

NAME                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/clickhouse-operator   1/1     1            1           170m

NAME                                             DESIRED   CURRENT   READY   AGE
replicaset.apps/clickhouse-operator-6fd75cbd68   1         1         1       170m

NAME                                     READY   AGE
statefulset.apps/chi-instana-local-0-0   1/1     158m
statefulset.apps/chi-instana-local-0-1   1/1     134m
```
## 7. Install Cert Manager
```sh
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.7.1/cert-manager.yaml
```
## 8. Create namespace for Instana Operator and required secret. Please make sure to put your valid **DOWNLOAD_KEY**
```sh
kubectl create ns instana-operator

kubectl create secret docker-registry instana-registry --namespace instana-operator \
    --docker-username=_ \
    --docker-password=<DOWNLOAD_KEY> \
    --docker-server=containers.instana.io
```
## 9. Add required permissions for service account:
```sh
oc adm policy add-scc-to-user anyuid -z instana-operator -n instana-operator
```
## 10. Create a file called *values.yaml* in /tmp. This will tell Instana operator which secret to use to pull containers: 
```sh
imagePullSecrets:
  - name: instana-registry 
```
## 11. Install Instana Operator:
```sh
kubectl instana operator apply --namespace=instana-operator --values /tmp/values.yaml
```

## 12.  Check if it is running `kubectl get pods -n instana-operator`. You should see one pod running:
```sh
NAME                               READY   STATUS    RESTARTS   AGE
instana-operator-d879c8c6c-ph56z   1/1     Running   0          108m
```
## 13. Create directories to hold yaml files of Instana Core:
```sh
mkdir instana-template; cd instana-template
kubectl instana template --output-dir /root/instana-template
```

## 14. Create two namespaces : *instana-core* , *instana-units* 
```
kubectl apply -f namespaces.yaml
```

## 15. Download Instana license. Please make sure to provide valid **SALES_KEY**
```
kubectl instana license download --sales-key <SALES_KEY>
```

## 16. Create Diffie-Hellman parameters for **instana-base**  secret 
```
openssl dhparam -out dhparams.pem 2048
```

## 17. Create **instana-registry** secret in **instana-core** and **instana-units** namespaces. Of coure provide valid **DOWNLOAD_KEY**
```
kubectl create secret docker-registry instana-registry --namespace instana-core \
    --docker-username=_ \
    --docker-password=<DOWNLOAD_KEY> \
    --docker-server=containers.instana.io
kubectl label secret instana-registry app.kubernetes.io/name=instana --namespace instana-core

kubectl create secret docker-registry instana-registry --namespace instana-units \
    --docker-username=_ \
    --docker-password=<DOWNLOAD_KEY> \
    --docker-server=containers.instana.io
kubectl label secret instana-registry app.kubernetes.io/name=instana --namespace instana-units
```
## 18. Create combined key/cert file. Provide *passw0rd* as pass phrase : 
```
openssl genrsa -aes128 -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 365
cat key.pem cert.pem > sp.pem
```
## 19. Create **Core** Secret.  

Create a file *config.yaml* with the following contents, provide *passw0rd* as pass phrase and put valid **DOWNLOAD_KEY**, **SALES_KEY**,  **SNIP_THE_CONTENTS_OF_dhparams.pem**, **SNIP_THE_CONTENTS_OF_key.pem** and **SNIP_THE_CONTENTS_OF_cert.pem**, please note indent:  
```
# The initial password for the admin user
adminPassword: passw0rd
# Diffie-Hellman parameters to use
dhParams: |
  -----BEGIN DH PARAMETERS-----
  <SNIP_THE_CONTENTS_OF_dhparams.pem/>
  -----END DH PARAMETERS-----
# The download key you received from us
downloadKey: <DOWNLOAD_KEY>
# The sales key you received from us
salesKey: <SALES_KEY>
# Seed for creating crypto tokens. Pick a random 12 char string
tokenSecret: mytokensecret
# Configuration for raw spans storage
#rawSpansStorageConfig:
  # Required if using S3 or compatible and credentials should be configured.
  # Not required if using IRSA on EKS.
  #s3Config:
    #accessKeyId: ...
    #secretAcessKey: ...
  # Required if using Google Cloud Storage and credentials should be configured.
  # Not required if using GKE with workload identity.
  #gcloudConfig:
    #serviceAccountKey: ...
# SAML/OIDC configuration
serviceProviderConfig:
  # Password for the key/cert file
  keyPassword: passw0rd
  # The combined key/cert file
  pem: |
    -----BEGIN RSA PRIVATE KEY-----
    <SNIP_THE_CONTENTS_OF_key.pem/>
    -----END RSA PRIVATE KEY-----
    -----BEGIN CERTIFICATE-----
    <SNIP_THE_CONTENTS_OF_cert.pem/>
    -----END CERTIFICATE-----
# Required if a proxy is configured that needs authentication
#proxyConfig:
  # Proxy user
  #user: myproxyuser
  # Proxy password
  #password: my proxypassword
#emailConfig:
  # Required if SMTP is used for sending e-mails and authentication is required
  #smtpConfig:
  #  user: mysmtpuser
  #  password: mysmtppassword
  # Required if using for sending e-mail and credentials should be configured.
  # Not required if using IRSA on EKS.
  #sesConfig:
  #  accessKeyId: ...
  #  secretAcessKey: ...
```
Create **instana-core** Secret 
```
kubectl create secret generic instana-core --namespace instana-core --from-file=./config.yaml
```
## 20. Create **instana-tls** secret. Provide baseDomain as CN  
```
openssl req -x509 -newkey rsa:2048 -keyout tls.key -out tls.crt -days 365 -nodes -subj "/CN=<YOUR_BASE_DOMAIN provided in core.yaml>"
kubectl create secret tls instana-tls --namespace instana-core --cert=tls.crt --key=tls.key
kubectl label secret instana-tls   app.kubernetes.io/name=instana -n instana-core
```
## 21. Create **Unit Secret**.  
Create a file *config.yaml* with the following contents, put valid **AGENT_KEY** and **SNIP_THE_CONTENTS_OF_license.json**:  
```
# The Instana license. an be a plain text string or a JSON array.
license: <SNIP_THE_CONTENTS_OF_license.txt>
# A list of agent keys. Currently, only the first key ist used.
# Future versions will allow multiple keys to be specified for better key management.
agentKeys:
  - <AGENT_KEY>
```
Assuming the Unit object's name is *tenant0-unit0*, create a Secret with the same name in the Unit's namespace.
```
kubectl create secret generic tenant0-unit0 --namespace instana-units --from-file=./config.yaml

```

## 22. Add required permissions for service accounts. Without those the pods will not start.  
Please note that it is possible that not all of those permissions are required.
```
oc adm policy add-scc-to-user anyuid  -z tenant0-unit0 -n instana-units
oc adm policy add-scc-to-user privileged  -z tenant0-unit0 -n instana-units
oc adm policy add-scc-to-user privileged  -z tenant0-unit0
oc adm policy add-scc-to-user anyuid  -z tenant0-unit0 
oc adm policy add-scc-to-user privileged -z default -n instana-core
oc adm policy add-scc-to-user anyuid -z default -n instana-core
oc adm policy add-scc-to-user anyuid -z default
oc adm policy add-scc-to-user privileged -z default 
oc adm policy add-scc-to-user privileged -z instana-core -n instana-core
oc adm policy add-scc-to-user privileged -z instana-core
oc adm policy add-scc-to-user anyuid -z instana-core -n instana-core
oc adm policy add-scc-to-user anyuid -z instana-core
```
## 23. Create **spans-volume-claim** and **appdata-writer** persistent volume claims  
```spans-volume-claim.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: spans-volume-claim
  namespace: instana-core
  labels:
    app.kubernetes.io/component: appdata-writer
    app.kubernetes.io/name: instana
    app.kubernetes.io/part-of: core
    instana.io/group: service
  finalizers:
    - kubernetes.io/pvc-protection
  selfLink: /api/v1/namespaces/instana-core/persistentvolumeclaims/spans-volume-claim
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 2Gi
  storageClassName: ocs-storagecluster-cephfs
  volumeMode: Filesystem 
```
```appdata-writer.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: appdata-writer
  namespace: instana-core
  labels:
    app.kubernetes.io/component: appdata-writer
    app.kubernetes.io/name: instana
    app.kubernetes.io/part-of: core
    instana.io/group: service
  finalizers:
    - kubernetes.io/pvc-protection
  selfLink: /api/v1/namespaces/instana-core/persistentvolumeclaims/appdata-writer
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 2Gi
  storageClassName: ocs-storagecluster-cephfs
  volumeMode: Filesystem
```
## 24. In */root/instana-template* there should be core.yaml file which needs to be updated as below for your environment.     
**Core.yaml** for Connecting to **instana datastores using 3-rd party vender operators**, provide valid **ACCEPTOR_DOMAIN** and **YOUR_BASE_DOMAIN** 
   ```
   apiVersion: instana.io/v1beta2
   kind: Core
   metadata:
     creationTimestamp: null
     name: instana-core
     namespace: instana-core
   spec:
     agentAcceptorConfig:
       host: <ACCEPTOR_DOMAIN>
       port: 443
     baseDomain: <YOUR_BASE_DOMAIN>
     componentConfigs:
       - name: acceptor
         replicas: 1
     datastoreConfigs:
       cassandraConfigs:
         - hosts: 
           - instana-cassandra-service.instana-cassandra
           ports:
             - name: tcp
               port: 9042
           keyspaces:
             - profiles
             - spans
             - metrics
       cockroachdbConfigs:
         - hosts: 
           - cockroachdb-public.instana-cockroachdb
           ports:
             - name: tcp
               port: 26257
           databases:
             - butlerdb
             - tenantdb
             - sales
       clickhouseConfigs:
         - hosts: 
           - chi-instana-local-0-0.instana-clickhouse
           - chi-instana-local-0-1.instana-clickhouse
           ports:
             - name: tcp
               port: 9000
             - name: http
               port: 8123
           schemas:
             - application
             - logs
           clusterName: local
       elasticsearchConfig:
         hosts: 
         - instana-es-http.instana-elastic
         ports:
           - name: tcp
             port: 9300
           - name: http
             port: 9200
         clusterName: onprem_onprem
       kafkaConfig:
         hosts: 
         - instana-kafka-bootstrap.instana-kafka
         ports:
           - name: tcp
             port: 9092
     emailConfig:
       smtpConfig:
         from: test@example.com
         host: example.com
         port: 465
         useSSL: false
     imageConfig:
       registry: containers.instana.io
     rawSpansStorageConfig:
       pvcConfig:
         resources:
           requests:
             storage: 2Gi
         storageClassName: ocs-storagecluster-cephfs
     resourceProfile: small
     imagePullSecrets:
       - name: instana-registry
   ```

## 25. Once the file is ready, please apply it `kubectl apply -f core.yaml`. You can check what is happening by looking at the events. Initially I found there information on permission issue causing pods' startup issues.
```
kubectl get events -n instana-core
```
## 26. If you don't see any errors you should eventually see pods running when you type: `kubectl get pods -n instana-core`
```
NAME                                         READY   STATUS    RESTARTS   AGE
acceptor-597bc9fdbb-pggbb                    1/1     Running   0          102m
accountant-6d8556b688-pbm6b                  1/1     Running   0          102m
appdata-health-processor-684ccdfc54-p54nk    1/1     Running   0          102m
appdata-live-aggregator-5dcfdff74c-r59lt     1/1     Running   0          102m
appdata-reader-78dc69f67-shj4s               1/1     Running   0          102m
appdata-writer-6d7f55c446-nvfmw              1/1     Running   0          102m
butler-669769bcf9-65htp                      1/1     Running   0          102m
cashier-ingest-d8bc55fc5-tlgjt               1/1     Running   0          102m
cashier-rollup-6457fb6dd-dspl8               1/1     Running   0          102m
eum-acceptor-78fb44c956-qwspf                1/1     Running   0          102m
eum-health-processor-679cff4944-r9v9g        1/1     Running   0          102m
eum-processor-7dc6b4d75c-6rwcv               1/1     Running   0          102m
gateway-c6bffd77d-dfzvr                      1/1     Running   0          83m
groundskeeper-68fcb7f464-d8l4t               1/1     Running   0          102m
js-stack-trace-translator-6b58bc6474-pt7gl   1/1     Running   0          102m
serverless-acceptor-6ffcb7d5d9-tdgcr         1/1     Running   0          102m
sli-evaluator-b54b99dc4-4s5lw                1/1     Running   0          102m
ui-client-87ffb6d5d-fjvq6                    1/1     Running   0          98m
```
## 27. Populate the **unit.yaml** file as below. 
```
apiVersion: instana.io/v1beta2
kind: Unit
metadata:
  namespace: instana-units
  name: tenant0-unit0
spec:
  # Must refer to the namespace of the associated Core object we created above
  coreName: instana-core

  # Must refer to the name of the associated Core object we created above
  coreNamespace: instana-core

  # The name of the tenant
  tenantName: tenant0

  # The name of the unit within the tenant
  unitName: unit0

  # The same rules apply as for Cores. May be ommitted. Default is 'medium'
  resourceProfile: small
```
## 28. When done, apply your settings: `kubectl apply -f unit.yaml`
## 29. Progress can be monitored with `kubectl get events -n instana-units`
## 30. Once process completes, you should get pods running `kubectl get pods -n instana-units`. Example output:
```
NAME                                                         READY   STATUS    RESTARTS   AGE
tu-tenant0-unit0-appdata-legacy-converter-86b44c54c8-9wf6q   1/1     Running   0          102m
tu-tenant0-unit0-appdata-processor-7c57b6bf77-swkpb          1/1     Running   0          102m
tu-tenant0-unit0-filler-7748957-hw6qq                        1/1     Running   0          102m
tu-tenant0-unit0-issue-tracker-6889cd4c55-5rvfc              1/1     Running   0          102m
tu-tenant0-unit0-processor-7cffdb74f-9t7pn                   1/1     Running   0          102m
tu-tenant0-unit0-ui-backend-7579657886-d7mnm                 1/1     Running   0          102m
```
## 31. Create a route for accessing the UI.  
   As hostname put unit0-tenant0.<YOUR_BASE_DOMAIN> ( baseDomain was specified in core.yaml ). I used *unit0-tenant0.apps.itzocp-665001jbi0-j816ol8l.cp.fyre.ibm.com*  
   ```
   oc create route passthrough ui-client-ssl --hostname=<your_hostname> --service=gateway --port=https -n instana-core
   ```
## 32. Create a route for agent acceptor  
   As hostname put <ACCEPTOR_DOMAIN> in core.yaml.  
   ```
   oc create route passthrough acceptor  --hostname=<ACCEPTOR_DOMAIN>  --service=acceptor  --port=8600  -n instana-core
   ```
## 33. Now you should be able to connect to your Instana by putting https://<your_hostname> in the browser
![](images/Instana.png)

## 34. If something is missing or not right in this tuotorial, please let me know. 
   

