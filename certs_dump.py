import base64
import yaml

d = yaml.load(open('/etc/rancher/k3s/k3s.yaml', 'r'))

# # save cluster ca certificate.
# for c in d['clusters']:
#     open(f"/vagrant/tmp/{c['name']}-ca-crt.pem", 'wb').write(base64.b64decode(c['cluster']['certificate-authority-data']))

# # save user client certificates.
# for u in d['users']:
#     open(f"/vagrant/tmp/{u['name']}-crt.pem", 'wb').write(base64.b64decode(u['user']['client-certificate-data']))
#     open(f"/vagrant/tmp/{u['name']}-key.pem", 'wb').write(base64.b64decode(u['user']['client-key-data']))
#     print(f"Kubernetes API Server https://$fqdn:6443 user {u['name']} client certificate in tmp/{u['name']}-*.pem")
# save user passwords.

for u in d['users']:
    open(f"/vagrant/tmp/{u['user']['username']}-password.txt", 'w').write(u['user']['password'])
    print(f"Kubernetes API Server https://$fqdn:6443 user {u['user']['username']} password {u['user']['password']}")

# set the server ip.
for c in d['clusters']:
    c['cluster']['server'] = 'https://$fqdn:6443'

yaml.dump(d, open('/vagrant/tmp/admin.conf', 'w'), default_flow_style=False)
