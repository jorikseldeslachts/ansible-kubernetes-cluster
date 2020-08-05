
https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/#config-file

REMOVE fucking entry from /etc/hosts tot 127.0.0.1
tree /etc/kubernetes ; tree /tmp/172*

# create kubeadm configs for etcd
export HOST1=10.42.0.21
export HOST2=10.42.0.22
export HOST3=10.42.0.23
mkdir -p /tmp/${HOST1}/ /tmp/${HOST2}/ /tmp/${HOST3}/

ETCDHOSTS=(${HOST1} ${HOST2} ${HOST3})
NAMES=("k8s-node-1" "k8s-node-2" "k8s-node-3")

for i in "${!ETCDHOSTS[@]}"; do
HOST=${ETCDHOSTS[$i]}
NAME=${NAMES[$i]}
cat << EOF > /tmp/${HOST}/kubeadm-init-etcd-cfg.yaml
apiVersion: "kubeadm.k8s.io/v1beta2"
kind: ClusterConfiguration
etcd:
  local:
    serverCertSANs:
    - "${HOST}"
    peerCertSANs:
    - "${HOST}"
    extraArgs:
      initial-cluster: ${NAMES[0]}=https://${ETCDHOSTS[0]}:2380,${NAMES[1]}=https://${ETCDHOSTS[1]}:2380,${NAMES[2]}=https://${ETCDHOSTS[2]}:2380
      initial-cluster-state: new
      name: ${NAME}
      listen-peer-urls: https://${HOST}:2380
      listen-client-urls: https://${HOST}:2379
      advertise-client-urls: https://${HOST}:2379
      initial-advertise-peer-urls: https://${HOST}:2380
EOF
done

# create ca
kubeadm init phase certs etcd-ca

# copy the certs
kubeadm init phase certs etcd-server --config=/tmp/${HOST3}/kubeadm-init-etcd-cfg.yaml
kubeadm init phase certs etcd-peer --config=/tmp/${HOST3}/kubeadm-init-etcd-cfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${HOST3}/kubeadm-init-etcd-cfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/tmp/${HOST3}/kubeadm-init-etcd-cfg.yaml
cp -R /etc/kubernetes/pki /tmp/${HOST3}/
# cleanup non-reusable certificates
find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete

kubeadm init phase certs etcd-server --config=/tmp/${HOST2}/kubeadm-init-etcd-cfg.yaml
kubeadm init phase certs etcd-peer --config=/tmp/${HOST2}/kubeadm-init-etcd-cfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${HOST2}/kubeadm-init-etcd-cfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/tmp/${HOST2}/kubeadm-init-etcd-cfg.yaml
cp -R /etc/kubernetes/pki /tmp/${HOST2}/
find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete

kubeadm init phase certs etcd-server --config=/tmp/${HOST1}/kubeadm-init-etcd-cfg.yaml
kubeadm init phase certs etcd-peer --config=/tmp/${HOST1}/kubeadm-init-etcd-cfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${HOST1}/kubeadm-init-etcd-cfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/tmp/${HOST1}/kubeadm-init-etcd-cfg.yaml
# No need to move the certs because they are for HOST0

# clean up certs that should not be copied off this host
find /tmp/${HOST3} -name ca.key -type f -delete
find /tmp/${HOST2} -name ca.key -type f -delete



# copy everything to all nodes
cp /tmp/${HOST1}/kubeadm-init-etcd-cfg.yaml /root/

scp -r /tmp/${HOST2}/* root@${HOST2}:
ssh root@${HOST2} mv /root/pki /etc/kubernetes/

scp -r /tmp/${HOST3}/* root@${HOST3}:
ssh root@${HOST3} mv /root/pki /etc/kubernetes/


# check for those files ( ALL NODES !!!)
# - apiserver-etcd-client.crt
# - apiserver-etcd-client.key
tree /etc/kubernetes

# check this ipaddress here
cat /root/kubeadm-init-etcd-cfg.yaml



# init etcd cluster by creating pod manifests ( ALL NODES !!!)
kubeadm init phase etcd local --config=/root/kubeadm-init-etcd-cfg.yaml
docker ps -a


# check / test
kubeadm config images list --kubernetes-version 1.18.6

ETCD_TAG=3.4.3-0
docker run --rm -it \
--net host \
-v /etc/kubernetes:/etc/kubernetes k8s.gcr.io/etcd:${ETCD_TAG} etcdctl \
--cert /etc/kubernetes/pki/etcd/peer.crt \
--key /etc/kubernetes/pki/etcd/peer.key \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--endpoints https://10.42.0.21:2379 endpoint health --cluster

ETCD_TAG=3.4.3-0
docker run --rm -it \
--net host \
-v /etc/kubernetes:/etc/kubernetes k8s.gcr.io/etcd:${ETCD_TAG} etcdctl \
--cert /etc/kubernetes/pki/etcd/peer.crt \
--key /etc/kubernetes/pki/etcd/peer.key \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--endpoints https://10.42.0.22:2379 endpoint health --cluster

ETCD_TAG=3.4.3-0
docker run --rm -it \
--net host \
-v /etc/kubernetes:/etc/kubernetes k8s.gcr.io/etcd:${ETCD_TAG} etcdctl \
--cert /etc/kubernetes/pki/etcd/peer.crt \
--key /etc/kubernetes/pki/etcd/peer.key \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--endpoints https://10.42.0.23:2379 endpoint health --cluster




# kubeadm-config.yaml
mv -i /etc/kubernetes/kubeadm/kubeadm-config.yml /etc/kubernetes/kubeadm/kubeadm-config.yml.old
cat << EOF > /etc/kubernetes/kubeadm/kubeadm-init-k8s-cluster-cfg.yml
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: stable
controlPlaneEndpoint: 10.42.0.25:6443
networking:
  podSubnet: 10.88.0.0/16
  serviceSubnet: 10.99.0.0/16
  dnsDomain: cluster.local
apiServer:
  certSANs:
  - localhost
  - 127.0.0.1
  - 10.42.0.25
  - 10.42.0.21
  - 10.42.0.22
  - 10.42.0.23
  - k8s-node-1
  - k8s-node-2
  - k8s-node-3
  - k8s-node-1.milkywaygalaxy.be
  - k8s-node-2.milkywaygalaxy.be
  - k8s-node-3.milkywaygalaxy.be
  extraArgs:
    advertise-address: 10.42.0.25
etcd:
  external:
    endpoints:
    - https://10.42.0.21:2379
    - https://10.42.0.22:2379
    - https://10.42.0.23:2379
    caFile: /etc/kubernetes/pki/etcd/ca.crt
    certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt
    keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key
EOF

# init cluster
systemctl status kubelet
systemctl stop kubelet

kubeadm config images pull

kubeadm init --skip-phases=etcd --config=/etc/kubernetes/kubeadm/kubeadm-init-k8s-cluster-cfg.yml --upload-certs --v=8 \
--ignore-preflight-errors=FileAvailable--etc-kubernetes-manifests-etcd.yaml,Port-2380,Port-2379,DirAvailable--var-lib-etcd
# ExternalEtcdVersion









################################################ test #######################################################
cat << EOF > /etc/kubernetes/kubeadm/kubeadm-init-k8s-cluster-cfg.yml
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: stable
controlPlaneEndpoint: 10.42.0.25:6443
networking:
  podSubnet: 10.88.0.0/16
  serviceSubnet: 10.99.0.0/16
  dnsDomain: cluster.local
apiServer:
  certSANs:
  - localhost
  - 127.0.0.1
  - 10.42.0.25
  - 10.42.0.21
  - 10.42.0.22
  - 10.42.0.23
  - k8s-node-1
  - k8s-node-2
  - k8s-node-3
  - k8s-node-1.milkywaygalaxy.be
  - k8s-node-2.milkywaygalaxy.be
  - k8s-node-3.milkywaygalaxy.be
  extraArgs:
    advertise-address: 10.42.0.25
EOF
etcd:
  external:
    endpoints:
    - https://10.42.0.21:2379
    - https://10.42.0.22:2379
    - https://10.42.0.23:2379
    caFile: /etc/kubernetes/pki/etcd/ca.crt
    certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt
    keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key
etcd:
  local:
    serverCertSANs:
    - "${HOST}"
    peerCertSANs:
    - "${HOST}"
    extraArgs:
      initial-cluster: ${NAMES[0]}=https://${ETCDHOSTS[0]}:2380,${NAMES[1]}=https://${ETCDHOSTS[1]}:2380,${NAMES[2]}=https://${ETCDHOSTS[2]}:2380
      initial-cluster-state: new
      name: ${NAME}
      listen-peer-urls: https://${HOST}:2380
      listen-client-urls: https://${HOST}:2379
      advertise-client-urls: https://${HOST}:2379
      initial-advertise-peer-urls: https://${HOST}:2380
EOF



cat /etc/systemd/system/kubelet.service.d/etcd-service-manager.conf

kubeadm init --config=/etc/kubernetes/kubeadm/kubeadm-init-k8s-cluster-cfg.yml --upload-certs



kubeadm token create --ttl 10h --print-join-command
kubeadm init phase upload-certs --upload-certs -  | grep -v upload-certs



kubeadm join 10.42.0.25:6443 \
  --token cazo9j.b8ndxovih3n3pp9n \
  --discovery-token-ca-cert-hash sha256:1bd1403acd7b76b8492e20f6a10bb4808d7d086f3fb3be7a09dbd60c4b6831f7 \
  --certificate-key ab7fbc5e884d525ef54f485746334dca279ddf5940cb327ed012d50fa0821f5b \
  --control-plane




#################################### test ###############################################

#### 1 NODE
cd /root

# create CA
openssl genrsa -out ca.key 2048
sudo sed -i '0,/RANDFILE/{s/RANDFILE/\#&/}' /etc/ssl/openssl.cnf
openssl req -new -key ca.key -subj "/CN=KUBERNETES-CA" -out ca.csr
openssl x509 -req -in ca.csr -signkey ca.key -CAcreateserial  -out ca.crt -days 1000


# generate certs ON 1 NODE
cat > openssl-etcd.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = 10.42.0.21
IP.2 = 10.42.0.22
IP.3 = 10.42.0.23
IP.4 = 127.0.0.1
EOF
openssl genrsa -out etcd-server.key 2048
openssl req -new -key etcd-server.key -subj "/CN=etcd-server" -out etcd-server.csr -config openssl-etcd.cnf
openssl x509 -req -in etcd-server.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out etcd-server.crt -extensions v3_req -extfile openssl-etcd.cnf -days 1000

# distribute
for instance in k8s-node-2 k8s-node-3; do
  scp \
	ca.crt \
	ca.key \
	etcd-server.key \
	etcd-server.crt \
	${instance}:/root/
done


#### ALL NODES
{
  rm -rf /etc/systemd/system/kubelet.service.d
  systemctl daemon-reload
  systemctl restart kubelet
  systemctl status kubelet
}
cd /root

ETCD_VER=v3.4.10
GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
DOWNLOAD_URL=${GITHUB_URL}

wget -q --show-progress --https-only --timestamping \
   ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz

{
  tar -xvf etcd-${ETCD_VER}-linux-amd64.tar.gz
  sudo mv etcd-${ETCD_VER}-linux-amd64/etcd* /usr/local/bin/
}

{
  mkdir -p /etc/etcd /var/lib/etcd
  chmod 0700 /var/lib/etcd
  cp ca.crt etcd-server.key etcd-server.crt /etc/etcd/
}

INTERNAL_IP=$(ip addr show ens18 | grep "inet " | awk '{print $2}' | cut -d / -f 1)
ETCD_NAME=$(hostname -s)
echo ${INTERNAL_IP}
echo ${ETCD_NAME}

cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd for k8s
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/etcd-server.crt \\
  --key-file=/etc/etcd/etcd-server.key \\
  --peer-cert-file=/etc/etcd/etcd-server.crt \\
  --peer-key-file=/etc/etcd/etcd-server.key \\
  --trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster k8s-node-1=https://10.42.0.21:2380,k8s-node-2=https://10.42.0.22:2380,k8s-node-3=https://10.42.0.23:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat /etc/systemd/system/etcd.service

{
  systemctl daemon-reload
  systemctl enable etcd
  systemctl restart etcd
  systemctl status etcd
}

ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.crt \
  --cert=/etc/etcd/etcd-server.crt \
  --key=/etc/etcd/etcd-server.key


# init master
cat << EOF > /etc/kubernetes/kubeadm/kubeadm-init-k8s-cluster-cfg.yml
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: stable
controlPlaneEndpoint: 10.42.0.25:6443
networking:
  podSubnet: 10.88.0.0/16
  serviceSubnet: 10.99.0.0/16
  dnsDomain: cluster.local
apiServer:
  certSANs:
  - localhost
  - 127.0.0.1
  - 10.42.0.25
  - 10.42.0.21
  - 10.42.0.22
  - 10.42.0.23
  - k8s-node-1
  - k8s-node-2
  - k8s-node-3
  - k8s-node-1.milkywaygalaxy.be
  - k8s-node-2.milkywaygalaxy.be
  - k8s-node-3.milkywaygalaxy.be
  extraArgs:
    advertise-address: 10.42.0.25
etcd:
  external:
    endpoints:
    - https://10.42.0.21:2379
    - https://10.42.0.22:2379
    - https://10.42.0.23:2379
    caFile: /etc/etcd/ca.crt
    certFile: /etc/etcd/etcd-server.crt
    keyFile: /etc/etcd/etcd-server.key
EOF

kubeadm init --config=/etc/kubernetes/kubeadm/kubeadm-init-k8s-cluster-cfg.yml --upload-certs --v=8

{
  mkdir -p /home/k8s/.kube
  cp -i /etc/kubernetes/admin.conf /home/k8s/.kube/config
  chown k8s:k8s /home/k8s/.kube/config
}








