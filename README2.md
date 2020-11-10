
Find control characters `cat /vagrant/canal.yaml | grep '[[:cntrl:]]'`
Traefik HTTP and HTTS CrashLoopBackOff #201 https://github.com/rancher/k3s/issues/201


https://rancher.com/docs/rancher/v2.x/en/installation/install-rancher-on-k8s/
```
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.0.4/cert-manager.crds.yaml
kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.0.4
kubectl get pods --namespace cert-manager
```
```
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=rancher.example.test
kubectl -n cattle-system rollout status deploy/rancher

kubectl -n cattle-system get deploy rancher

helm uninstall rancher -n cattle-system
```
```
kubectl run -it --image=debian --restart=Never shell -- \
sh -c 'apt-get update > /dev/null && apt-get install -y dnsutils > /dev/null && \
nslookup kubernetes.default | grep Name | sed "s/Name:\skubernetes.default//"'

kubectl delete pod shell

sudo kubectl run -it --image=debian --restart=Never shell /bin/bash
apt-get update
apt-get install -y dnsutils
nslookup kubernetes.default
```

```shell script
vagrant plugin install vagrant-hosts
```

```shell script
k3s_channel="stable";
k3s_version="v1.18.10+k3s2";
k3s_token="7e982a7bbac5f385ecbb988f800787bc9bb617552813a63c4469521c53d83b6e";
ip_address="10.11.0.101";
krew_version="v0.4.0";
fqdn="$(hostname --fqdn)"

#curl -sfL https://raw.githubusercontent.com/rancher/k3s/v1.18.10+k3s2/install.sh | INSTALL_K3S_VERSION="v1.18.10+k3s2" sh -
curl -sfL https://get.k3s.io \
    | \
        INSTALL_K3S_CHANNEL="stable" \
        INSTALL_K3S_VERSION="v1.18.10+k3s2" \
        K3S_TOKEN="7e982a7bbac5f385ecbb988f800787bc9bb617552813a63c4469521c53d83b6e" \
        sh -s -- \
            server \
            --no-deploy traefik \
            --node-ip "10.11.0.101" \
            --cluster-cidr '10.12.0.0/16' \
            --service-cidr '10.13.0.0/16' \
            --cluster-dns '10.13.0.10' \
            --cluster-domain 'cluster.local' \
            --flannel-iface 'eth1'

sudo journalctl -xef -u k3s.service

curl -o traefik.yaml "https://raw.githubusercontent.com/rancher/k3s/$k3s_version/manifests/traefik.yaml"
apt-get install -y python3-yaml
python3 traefik_dashboard.py
kubectl -n kube-system apply -f traefik.yaml
crictl pods --label app=svclb-traefik

apt-get install -y --no-install-recommends git-core
wget -qO- "https://github.com/kubernetes-sigs/krew/releases/download/$krew_version/krew.tar.gz" | tar xzf - ./krew-linux_amd64
wget -q "https://github.com/kubernetes-sigs/krew/releases/download/$krew_version/krew.yaml"
./krew-linux_amd64 install --manifest=krew.yaml
echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' | tee /etc/profile.d/krew.sh
source /etc/profile.d/krew.sh
kubectl krew version

# symlink the default kubeconfig path so local tools like k9s can easily
# find it without exporting the KUBECONFIG environment variable.
ln -s /etc/rancher/k3s/k3s.yaml ~/.kube/config
mkdir -p /vagrant/tmp
python3 certs_dump.py

kubectl cluster-info
kubectl get nodes -o wide
```

https://github.com/rgl/k3s-vagrant

Fedora 31 see:
https://github.com/randy-stad/k3s-vagrant-cluster

Build cilium in
https://cilium.io/blog/2020/04/29/cilium-with-rancher-labs-k3s/

see also: https://tferdinand.net/en/create-a-local-kubernetes-cluster-with-vagrant/
