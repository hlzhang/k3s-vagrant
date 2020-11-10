#!/bin/bash
set -eux

# NB do not try to use kubectl on a agent node, as kubectl does not work on a
#    agent node without a proper kubectl configuration (which you could copy
#    from the server).

# wait for the svclb-traefik pod to be Running.
# e.g. eca1ea99515cd       About an hour ago   Ready               svclb-traefik-kz562   kube-system         0
$SHELL -c 'while [ -z "$(crictl pods --label app=svclb-traefik | grep -E "\s+Ready\s+")" ]; do sleep 3; done'

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
crictl version
k3s ctr version
