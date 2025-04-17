# Local Infra

This project provides a fully self-hosted local development environment composed of essential services like Traefik, Step-CA, SMTP4Dev, Gogs, and more. It is built around Docker and controlled using Bash scripts for simplicity and flexibility.

The goal is to offer an all-in-one setup for local development, with built-in support for automatic HTTPS (via ACME and Step-CA), DNS record handling, Git hosting, and SMTP testing—all containerized and easily manageable.

## Features

- **Step-CA** for private CA and ACME support.
- **Traefik** as a reverse proxy and automatic certificate manager.
- **SMTP4Dev** for testing emails in development.
- **Gogs** for self-hosted Git repositories.
- **Dagger Engine** support for CI/CD and automated workflows (optional).

- **Docker-based setup**, orchestrated by simple Bash scripts.
- **Automatic DNS record handling** for containers via labels and AdGuardHome.

## Apps

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

## Kubernetes Environments

You can spin up a test Kubernetes cluster using one of the following methods:

- **Kind** (Kubernetes in Docker)
- **Minikube** (Local Kubernetes with VM or Docker backend)
- **K3s on Debian VM** via `virt-install`

https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/

### Example Usage

```shell
# Start Kind cluster
./scripts/k8s/10-kind.sh

# OR Minikube
./scripts/k8s/11-minikube.sh

# OR K3s in a VM
./scripts/k8s/12-kvm-k3s.sh
```

## License

This project is licensed under the [MIT License](./LICENSE) © 2024-2025 juli3nk.
