#!/bin/bash
set -e

# Logs visibles via cloud-init-output.log
exec > >(tee /var/log/user-data.log) 2>&1

echo "=========================================="
echo "Démarrage de la configuration de l'instance"
echo "=========================================="

# 1. Dépendances de base
echo "[1/7] Installation des dépendances..."
apt-get update -y
apt-get install -y software-properties-common git python3-pip curl jq

# 2. Installation Ansible
echo "[2/7] Installation d'Ansible..."
pip3 install ansible

# 3. Récupération du tag Name depuis les métadonnées EC2
echo "[3/7] Récupération du rôle de l'instance..."
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null)
REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null)

# Récupération du tag Role de l'instance
ROLE=$(aws ec2 describe-tags \
  --region "$REGION" \
  --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Role" \
  --query "Tags[0].Value" \
  --output text 2>/dev/null || echo "unknown")

echo "Instance ID: $INSTANCE_ID"
echo "Region: $REGION"
echo "Role détecté: $ROLE"

# 4. Configuration du rôle pour Ansible
echo "[4/7] Configuration du rôle Ansible..."
mkdir -p /etc/ansible
echo "role=$ROLE" > /etc/ansible/role.conf
chmod 644 /etc/ansible/role.conf

cat /etc/ansible/role.conf
echo "Fichier de configuration créé: /etc/ansible/role.conf"

# 5. Répertoire de travail Ansible
echo "[5/7] Création du répertoire de travail..."
mkdir -p /opt/ansible
chown root:root /opt/ansible

# 6. Premier run Ansible Pull
echo "[6/7] Exécution d'Ansible Pull..."
ansible-pull \
  -d /opt/ansible \
  -U https://github.com/AristideWafo/gitops-ansible-pull.git \
  -C main \
  -i localhost, \
  -e "instance_role=$ROLE" \
  playbooks/site.yml

# 7. Configuration du timer systemd pour les exécutions périodiques
echo "[7/7] Configuration du timer systemd..."
if [ -f /opt/ansible/systemd/ansible-pull.service ] && [ -f /opt/ansible/systemd/ansible-pull.timer ]; then
  cp /opt/ansible/systemd/ansible-pull.service /etc/systemd/system/
  cp /opt/ansible/systemd/ansible-pull.timer /etc/systemd/system/

  systemctl daemon-reload
  systemctl enable --now ansible-pull.timer
  echo "Timer systemd configuré et activé"
else
  echo "Fichiers systemd non trouvés, configuration manuelle du cron..."
  # Fallback sur cron si les fichiers systemd ne sont pas présents
  echo "*/15 * * * * root ansible-pull -d /opt/ansible -U https://github.com/AristideWafo/gitops-ansible-pull.git -C main -i localhost, -e \"instance_role=$ROLE\" playbooks/site.yml >> /var/log/ansible-pull.log 2>&1" > /etc/cron.d/ansible-pull
  chmod 644 /etc/cron.d/ansible-pull
  echo "Cron configuré pour exécution toutes les 15 minutes"
fi

echo "=========================================="
echo "Configuration terminée avec succès!"
echo "Rôle: $ROLE"
echo "=========================================="
