#!/bin/bash
set -eux

kubernetes_dashboard_version="${1:-v2.0.4}"; shift || true
kubernetes_dashboard_url="https://raw.githubusercontent.com/kubernetes/dashboard/$kubernetes_dashboard_version/aio/deploy/recommended.yaml"

# install the kubernetes dashboard.
# NB this installs in the kubernetes-dashboard namespace.
# see https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/
# see https://github.com/kubernetes/dashboard/releases
kubectl apply -f "$kubernetes_dashboard_url"

# create the admin user.
# see https://github.com/kubernetes/dashboard/wiki/Creating-sample-user
# see https://github.com/kubernetes/dashboard/wiki/Access-control
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: admin
    namespace: kubernetes-dashboard
EOF
# save the admin token.
kubectl \
  -n kubernetes-dashboard \
  get \
  secret \
  $(kubectl -n kubernetes-dashboard get secret | grep admin-token- | awk '{print $1}') \
  -o json | jq -r .data.token | base64 --decode \
  >/vagrant/tmp/admin-token.txt

# expose the kubernetes dashboard at kubernetes-dashboard.example.com.
# NB you must add any of the cluster node IP addresses to your computer hosts file, e.g.:
#       10.10.10.101 kubernetes-dashboard.example.com
#    and access it as:
#       https://kubernetes-dashboard.example.com
# see kubectl get -n kubernetes-dashboard service/kubernetes-dashboard -o yaml
# see https://docs.traefik.io/providers/kubernetes-ingress/
# see https://docs.traefik.io/routing/providers/kubernetes-crd/
# see https://kubernetes.io/docs/concepts/services-networking/ingress/
# see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#ingress-v1-networking-k8s-io
kubectl apply -n kubernetes-dashboard -f - <<'EOF'
kind: Ingress
apiVersion: networking.k8s.io/v1
metadata:
  name: kubernetes-dashboard
spec:
  rules:
    # NB you can use any other host, but you have to make sure DNS resolves to one of k8s cluster IP addresses.
    # NB you can see the traefik configuration with:
    #       kubectl --namespace kube-system get $(kubectl --namespace kube-system get pods -l app=traefik -o name) -o yaml
    #       kubectl --namespace kube-system get configMap/traefik -o yaml
    #       kubectl --namespace kube-system logs $(kubectl --namespace kube-system get pods -l app=traefik -o name)
    - host: kubernetes-dashboard.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kubernetes-dashboard
                port:
                  number: 443
EOF
