#!/bin/bash

set -e

SSH_PORT=2156
JAIL_CONF="/etc/fail2ban/jail.local"

log() {
  echo -e "\e[32m[INFO]\e[0m $1"
}

error() {
  echo -e "\e[31m[ERROR]\e[0m $1" >&2
}

log "Updating package list..."
apt update -y

SSHD_CONFIG="/etc/ssh/sshd_config"

if grep -q "^Port $SSH_PORT" "$SSHD_CONFIG"; then
  log "SSH port is already set to $SSH_PORT"
else
  log "Changing SSH port to $SSH_PORT..."
  if grep -q "^Port" "$SSHD_CONFIG"; then
    sed -i "s/^Port .*/Port $SSH_PORT/" "$SSHD_CONFIG"
  else
    echo "Port $SSH_PORT" >> "$SSHD_CONFIG"
  fi
  log "Restarting SSH service..."
  systemctl restart ssh || systemctl restart sshd || error "Failed to restart SSH"
fi

if grep -q "^net.ipv4.icmp_echo_ignore_all=1" /etc/sysctl.conf; then
  log "ICMP ignore is already configured"
else
  log "Disabling ICMP echo replies..."
  echo "net.ipv4.icmp_echo_ignore_all=1" >> /etc/sysctl.conf
  sysctl -p
fi

log "Installing fail2ban and vim..."
apt install -y fail2ban vim

log "Configuring fail2ban for SSH..."

mkdir -p /etc/fail2ban

cat > "$JAIL_CONF" <<EOF
[sshd]
enabled = true
port = $SSH_PORT
logpath = %(sshd_log)s
backend = systemd
EOF

systemctl enable fail2ban
systemctl restart fail2ban

log "Done! SSH is now on port $SSH_PORT, ICMP echo is disabled, fail2ban is active."
log "Verify connection with: ssh -p $SSH_PORT user@host"

