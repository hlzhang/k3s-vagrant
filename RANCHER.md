
https://rancher.com/docs/rancher/v2.x/en/installation/install-rancher-on-k8s/
```shell script
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
#helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
kubectl create namespace cattle-system

kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.0.4/cert-manager.crds.yaml
kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.0.4
kubectl get pods --namespace cert-manager

kubectl logs deployment.apps/cert-manager -n cert-manager

helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=rancher.example.com \
  --set ingress.tls.source=rancher \
  --set replicas=1
kubectl -n cattle-system rollout status deploy/rancher
kubectl -n cattle-system get deploy rancher
```

```shell script
kubectl get all,cm,secret,ing -A
kubectl get namespace,replicaset,secret,nodes,job,daemonset,statefulset,ingress,configmap,pv,pvc,service,deployment,pod --all-namespaces

kubectl get deployment -n cattle-system
kubectl describe deploy rancher -n cattle-system
kubectl logs deployment.apps/rancher -n cattle-system

kubectl logs rancher-7b8f5ddbf7-jfq7r -n cattle-system -p
kubectl logs rancher-7b8f5ddbf7-8w42j -n cattle-system -p

kubectl run --rm -it --image=debian --restart=Never shell /bin/bash
```
