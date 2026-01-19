pip3 install ansible
#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

ANSIBLE_REPO="${ANSIBLE_REPO:-https://github.com/AristideWafo/gitops-ansible-pull.git}"
ANSIBLE_BRANCH="${ANSIBLE_BRANCH:-prod}"
ANSIBLE_DIR="${ANSIBLE_DIR:-/opt/ansible}"
ANSIBLE_VERSION="${ANSIBLE_VERSION:-10.7.0}"

# Logs visibles via cloud-init-output.log
exec > >(tee /var/log/user-data.log) 2>&1

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"
}

log "==== Initialisation de l'instance ===="

log "[1/6] Installation des dépendances système"
apt-get update -y
apt-get install -y --no-install-recommends \
  software-properties-common \
  git \
  python3-pip \
  curl \
  jq

log "[2/6] Installation d'Ansible ${ANSIBLE_VERSION}"
pip3 install --upgrade pip
pip3 install "ansible==${ANSIBLE_VERSION}"

log "[3/6] Lecture des métadonnées EC2"
TOKEN=$(curl -fs -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)

metadata() {
  local path="$1"
  if [ -n "$TOKEN" ]; then
    curl -fs "http://169.254.169.254/latest/meta-data/${path}" -H "X-aws-ec2-metadata-token: ${TOKEN}" || true
  else
    curl -fs "http://169.254.169.254/latest/meta-data/${path}" || true
  fi
}

INSTANCE_ID=$(metadata "instance-id")
REGION=$(metadata "placement/region")
ROLE=$(metadata "tags/instance/Role")

if [ -z "$ROLE" ] || [ "$ROLE" = "NotFound" ]; then
  ROLE=$(metadata "tags/instance/Name")
fi

ROLE=${ROLE:-unknown}
log "Instance ID: ${INSTANCE_ID:-n/a} | Region: ${REGION:-n/a} | Role: ${ROLE}"

log "[4/6] Création du fichier de rôle"
mkdir -p /etc/ansible
printf "role=%s\n" "$ROLE" > /etc/ansible/role.conf
chmod 0644 /etc/ansible/role.conf

log "[5/6] Préparation du répertoire ${ANSIBLE_DIR}"
mkdir -p "$ANSIBLE_DIR"
chown root:root "$ANSIBLE_DIR"

log "[6/6] Exécution d'ansible-pull (${ANSIBLE_BRANCH})"
ansible-pull \
  -d "$ANSIBLE_DIR" \
  -U "$ANSIBLE_REPO" \
  -C "$ANSIBLE_BRANCH" \
  -i localhost, \
  -e "instance_role=$ROLE" \
  playbooks/site.yml

if [ -f "$ANSIBLE_DIR/systemd/ansible-pull.service" ] && [ -f "$ANSIBLE_DIR/systemd/ansible-pull.timer" ]; then
  log "Activation du timer systemd ansible-pull"
  cp "$ANSIBLE_DIR/systemd/ansible-pull.service" /etc/systemd/system/
  cp "$ANSIBLE_DIR/systemd/ansible-pull.timer" /etc/systemd/system/
  systemctl daemon-reload
  systemctl enable --now ansible-pull.timer
else
  log "Timer systemd introuvable, configuration d'un cron toutes les 15 minutes"
  cat <<EOF >/etc/cron.d/ansible-pull
*/15 * * * * root ansible-pull -d ${ANSIBLE_DIR} -U ${ANSIBLE_REPO} -C ${ANSIBLE_BRANCH} -i localhost, -e "instance_role=${ROLE}" playbooks/site.yml >> /var/log/ansible-pull.log 2>&1
EOF
  chmod 0644 /etc/cron.d/ansible-pull
fi

log "Configuration terminée"
