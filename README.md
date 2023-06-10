# Local Infra

## Network

Create docker network named `external`

```shell
./setup-network.sh
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
./run-ca.sh
```

Bootstrap

```shell
./ca-bootstrap.sh "https://ca.DOMAIN:8443" "FINGERPRINT"
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

### E-mail

```shell
./run-email.sh
```

### Traefik

```shell
./run-traefik.sh
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

### Git

```shell
./run-git.sh
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


### Registry

```shell
./run-registry.sh
```

### Kind

https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/

```shell
./run-kind.sh
```
