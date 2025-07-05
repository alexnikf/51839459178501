#!/bin/bash

set -e

echo
read -p "Enter last octet for WireGuard subnet (XXX in 192.168.XXX.0/24): " OCTET

if [[ ! "$OCTET" =~ ^[0-9]{1,3}$ ]] || (( OCTET < 1 || OCTET > 254 )); then
    echo "[ERROR] Invalid subnet octet. Must be number 1–254."
    exit 1
fi

SUBNET="192.168.$OCTET"
echo "[INFO] Subnet will be $SUBNET.0/24"

INSTALLER="wireguard-install.sh"

if [[ ! -f $INSTALLER ]]; then
    echo "[INFO] Downloading WireGuard installer..."
    wget -q https://git.io/wireguard -O "$INSTALLER"
    chmod +x "$INSTALLER"
fi

sed -i "s/10\\.7\\.0/$SUBNET/g" "$INSTALLER"

# если WireGuard уже установлен, просто добавим клиента
if [[ -f /etc/wireguard/wg0.conf ]]; then
    echo "[INFO] WireGuard already installed. Adding client 'user'..."
    bash "$INSTALLER" --add-client user --client-port 51829 --client-dns 2
else
    export NEEDRESTART_MODE=a
    echo
    echo "[ACTION REQUIRED] Please answer ONLY 'Which IPv4 address should be used?'"
    (
      sleep 1
      echo ""      # default port
      sleep 1
      echo "user"
      sleep 1
      echo "2"
      sleep 1
      echo ""
    ) | bash "$INSTALLER"
fi

echo
echo "[✅] Done! Client config for 'user':"
cat /root/user.conf
