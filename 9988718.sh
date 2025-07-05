#!/bin/bash
set -e

# Скачиваем и патчим установщик WireGuard
wget -q https://git.io/wireguard -O wireguard-install.sh
sed -i 's/10\.7\.0/192.168.10/g' wireguard-install.sh

# Запускаем установку
bash wireguard-install.sh

# Показываем конфиг клиента
echo
echo "[📄] WireGuard config (user):"
cat /root/user.conf || echo "[!] user.conf not found"

# Проверка статуса
echo
echo -n "Port: "
ss -tnlp | grep sshd | awk '{print $4}' | sed 's/.*://g' | sort -u

sysctl -p | grep net.ipv4.icmp_echo_ignore_all

if fail2ban-client status sshd &>/dev/null; then
    echo "fail2ban: yes"
else
    echo "fail2ban: no"
fi

