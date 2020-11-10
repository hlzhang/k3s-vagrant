#!/bin/bash
set -eux

k3s_version="${1:-v1.18.10+k3s2}"; shift
krew_version="${1:-v0.4.0}"; shift || true # NB see https://github.com/kubernetes-sigs/krew

# wait for this node to be Ready.
# e.g. s1     Ready    master   3m    v1.19.3+k3s2
$SHELL -c 'node_name=$(hostname); echo "waiting for node $node_name to be ready..."; while [ -z "$(kubectl get nodes $node_name | grep -E "$node_name\s+Ready\s+")" ]; do sleep 3; done; echo "node ready!"'

# wait for the kube-dns pod to be Running.
# e.g. coredns-fb8b8dccf-rh4fg   1/1     Running   0          33m
$SHELL -c 'while [ -z "$(kubectl get pods --selector k8s-app=kube-dns --namespace kube-system | grep -E "\s+Running\s+")" ]; do sleep 3; done'

# install traefik as the k8s ingress controller.
# see https://docs.traefik.io/v1.7/configuration/api/
# see https://github.com/rancher/k3s/issues/350#issuecomment-511218588
# see https://github.com/rancher/k3s/blob/v1.19.3+k3s2/scripts/download#L16
# see https://github.com/helm/charts/tree/master/stable/traefik
# see https://kubernetes-charts.storage.googleapis.com/traefik-1.81.0.tgz
echo 'patching traefik to expose its api/dashboard at http://traefik-dashboard.example.com...'
wget -q https://raw.githubusercontent.com/rancher/k3s/$k3s_version/manifests/traefik.yaml
apt-get install -y python3-yaml
python3 /vagrant/traefik_dashboard.py
kubectl -n kube-system apply -f traefik.yaml
#rm traefik.yaml

# wait for the svclb-traefik pod to be Running.
# e.g. eca1ea99515cd       About an hour ago   Ready               svclb-traefik-kz562   kube-system         0
$SHELL -c 'while [ -z "$(crictl pods --label app=svclb-traefik | grep -E "\s+Ready\s+")" ]; do sleep 3; done'

# install the krew kubectl package manager.
echo "installing the krew $krew_version kubectl package manager..."
apt-get install -y --no-install-recommends git-core
wget -qO- "https://github.com/kubernetes-sigs/krew/releases/download/$krew_version/krew.tar.gz" | tar xzf - ./krew-linux_amd64
wget -q "https://github.com/kubernetes-sigs/krew/releases/download/$krew_version/krew.yaml"
./krew-linux_amd64 install --manifest=krew.yaml
rm krew-linux_amd64
cat >/etc/profile.d/krew.sh <<'EOF'
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
EOF
source /etc/profile.d/krew.sh
kubectl krew version

# symlink the default kubeconfig path so local tools like k9s can easily
# find it without exporting the KUBECONFIG environment variable.
ln -sf /etc/rancher/k3s/k3s.yaml ~/.kube/config

# save kubeconfig in the host.
# NB the default users are generated at https://github.com/rancher/k3s/blob/v1.19.3+k3s2/pkg/daemons/control/server.go#L448
#    and saved at /var/lib/rancher/k3s/server/cred/passwd
mkdir -p /vagrant/tmp
fqdn="$(hostname --fqdn)"
python3 /vagrant/certs_dump.py "${fqdn}"

# show cluster-info.
kubectl cluster-info

# list nodes.
kubectl get nodes -o wide

# rbac info.
kubectl get serviceaccount --all-namespaces
kubectl get role --all-namespaces
kubectl get rolebinding --all-namespaces
kubectl get rolebinding --all-namespaces -o json | jq .items[].subjects
kubectl get clusterrole --all-namespaces
kubectl get clusterrolebinding --all-namespaces
kubectl get clusterrolebinding --all-namespaces -o json | jq .items[].subjects

# rbac access matrix.
# see https://github.com/corneliusweig/rakkess/blob/master/doc/USAGE.md
kubectl krew install access-matrix
kubectl access-matrix version --full
kubectl access-matrix # at cluster scope.
kubectl access-matrix --namespace default
kubectl access-matrix --sa kubernetes-dashboard --namespace kubernetes-dashboard

# list system secrets.
kubectl -n kube-system get secret

# list all objects.
# NB without this hugly redirect the kubectl output will be all messed
#    when used from a vagrant session.
kubectl get all --all-namespaces >/tmp/kubectl-$$.tmp; cat /tmp/kubectl-$$.tmp; rm /tmp/kubectl-$$.tmp

# really get all objects.
# see https://github.com/corneliusweig/ketall/blob/master/doc/USAGE.md
kubectl krew install get-all
kubectl get-all

# list services.
kubectl get svc

# list running pods.
kubectl get pods --all-namespaces

# list runnnig pods.
crictl pods

# list running containers.
crictl ps
k3s ctr containers ls

# show listening ports.
ss -n --tcp --listening --processes

# show network routes.
ip route

# show memory info.
free

# show versions.
kubectl version
crictl version
k3s ctr version
