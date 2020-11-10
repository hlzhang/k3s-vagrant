#!/bin/bash
set -eux

k3s_channel="$1"; shift
k3s_version="$1"; shift
k3s_token="$1"; shift
k3s_url="$1"; shift
ip_address="$1"; shift

# configure the motd.
# NB this was generated at http://patorjk.com/software/taag/#p=display&f=Big&t=k3s%0Aagent.
#    it could also be generated with figlet.org.
cat >/etc/motd <<'EOF'

  _    ____
 | |  |___ \
 | | __ __) |___
 | |/ /|__ </ __|        _
 |   < ___) \__ \       | |
 |_|\_\____/|___/_ _ __ | |_
  / _` |/ _` |/ _ \ '_ \| __|
 | (_| | (_| |  __/ | | | |_
  \__,_|\__, |\___|_| |_|\__|
         __/ |
        |___/

EOF

# install k3s.
curl -sfL https://raw.githubusercontent.com/rancher/k3s/$k3s_version/install.sh \
    | \
        INSTALL_K3S_CHANNEL="$k3s_channel" \
        INSTALL_K3S_VERSION="$k3s_version" \
        K3S_TOKEN="$k3s_token" \
        K3S_URL="$k3s_url" \
        sh -s -- \
            agent \
            --node-ip "$ip_address" \
            --flannel-iface 'eth1'

# see the systemd unit.
systemctl cat k3s-agent
