# Local Infra

## Network

Create docker network named `external`

```shell
./run-00-network.sh
```

## Apps

### DNS

### Step CA

Init step ca and copy the FINGERPRINT

```shell
./ca-init.sh
```

Put the password previously chosen into /home/step/secrets/password

```shell
./ca-password-secret.sh
```

Run step-ca docker container

```shell
./run-01-ca.sh
```

Bootstrap

```shell
./ca-bootstrap.sh "https://ca.[DOMAIN]:8443" "[FINGERPRINT]"
```

Add ACME provider

```shell
./ca-acme-add.sh traefik
```

#### Add CA to trust

```shell
step certificate install certs/root_ca.crt
```

Restart service

#### Ubuntu

https://ubuntu.com/server/docs/security-trust-store

#### Browser

Contrary to popular belief, you can get Firefox to look at the system certificates instead its own hard-coded set.

To do this, you will want to use a package called `p11-kit`. p11-kit provides a drop-in replacement for `libnssckbi.so`, the shared library that contains the hardcoded set of certificates. The p11-kit version instead reads the certificates from the system certificate store.

Since Firefox ships with its own version of libnssckbi.so, you'll need to track it down and replace it instead of the version provided in libnss3:

```shell
sudo mv /usr/lib/firefox/libnssckbi.so /usr/lib/firefox/libnssckbi.so.bak
sudo ln -s /usr/lib/x86_64-linux-gnu/pkcs11/p11-kit-trust.so /usr/lib/firefox/libnssckbi.so
```

Next, delete the ~/.pki directory to get Firefox to refresh its certificate database (causing it to pull in the system certs) upon restarting Firefox. Note: this will delete any existing certificates in the store, so if have custom ones that you added manually, you might want to back up that folder and then re-import them.

https://support.mozilla.org/en-US/kb/setting-certificate-authorities-firefox
Setting security.enterprise_roots.enabled to true

### E-mail

```shell
./run-02-email.sh
```

### Traefik

```shell
./run-03-traefik.sh
```

```cli
--label "traefik.enable=true"
--label "tag=app-external"
--label "traefik.docker.network=external"
--label "traefik.http.services.SERVICE_NAME.loadbalancer.server.port=SERVICE_PORT"
--label "traefik.http.routers.SERVICE_NAME.service=SERVICE_NAME"
--label "traefik.http.routers.SERVICE_NAME.rule=Host(`HOSTNAME`)"
--label "traefik.http.routers.SERVICE_NAME.entrypoints=https"
--label "traefik.http.routers.SERVICE_NAME.tls=true"
--label "traefik.http.routers.SERVICE_NAME.tls.certResolver=stepca"
```


### Registry

```shell
./run-04-registry.sh
```

### Kind

https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/

```shell
./run-05-kind.sh
```

### Git

```shell
./run-81-git.sh
```

#  > "${LOCAL_DATA_PATH}/gogs/custom/conf/app.ini"
cat << EOF
[server]
DOMAIN = ${LOCAL_DOMAIN}

[email]
ENABLED = true
HOST = smtp.${LOCAL_DOMAIN}:25
FROM = noreply@${DNS_RECORD}
USER = noreply@${DNS_RECORD}
EOF

### Longhorn

apt install open-iscsi nfs-common

