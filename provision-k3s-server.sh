#!/bin/bash
set -eux

k3s_channel="${1:-latest}"; shift
k3s_version="${1:-v1.19.3+k3s2}"; shift
k3s_token="$1"; shift
ip_address="$1"; shift

# configure the motd.
# NB this was generated at http://patorjk.com/software/taag/#p=display&f=Big&t=k3s%0Aserver.
#    it could also be generated with figlet.org.
cat >/etc/motd <<'EOF'

  _    ____
 | |  |___ \
 | | __ __) |___
 | |/ /|__ </ __|
 |   < ___) \__ \
 |_|\_\____/|___/   _____ _ __
 / __|/ _ \ '__\ \ / / _ \ '__|
 \__ \  __/ |   \ V /  __/ |
 |___/\___|_|    \_/ \___|_|

EOF

# install k3s.
# see server arguments at e.g. https://github.com/rancher/k3s/blob/v1.19.3+k3s2/pkg/cli/cmds/server.go#L71
# or run k3s server --help
# see https://rancher.com/docs/k3s/latest/en/configuration/
curl -sfL https://raw.githubusercontent.com/rancher/k3s/$k3s_version/install.sh \
    | \
        INSTALL_K3S_CHANNEL="$k3s_channel" \
        INSTALL_K3S_VERSION="$k3s_version" \
        K3S_TOKEN="$k3s_token" \
        sh -s -- \
            server \
            --no-deploy traefik \
            --node-ip "$ip_address" \
            --cluster-cidr '10.12.0.0/16' \
            --service-cidr '10.13.0.0/16' \
            --cluster-dns '10.13.0.10' \
            --cluster-domain 'cluster.local' \
            --flannel-backend=none
            # --flannel-iface 'eth1'

# see the systemd unit.
systemctl cat k3s

kubectl apply -f /vagrant/canal.yaml
