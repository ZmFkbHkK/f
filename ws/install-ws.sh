#!/bin/bash

file_path="/etc/handeling"
repo="https://raw.githubusercontent.com/kipasu/f/main"

apt update
apt install python3 -y
apt install python3-pip -y

function wspy(){
apt install python3-requests -y

if [ ! -f "$file_path" ]; then
echo -e "Switching Protocols\nYellow" | sudo tee "$file_path" > /dev/null
fi

cd /usr/local/bin
wget -q -O vpn.zip "${repo}/ws/vpn.zip"
unzip vpn.zip >/dev/null 2>&1
cp ws ws-ovpn
chmod +x ws ws-ovpn
rm vpn.zip
cd

# Installing Service
cat > /etc/systemd/system/ws.service << END
[Unit]
Description=Websocket
Documentation=https://google.com
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/ws
Restart=on-failure

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable ws.service
systemctl start ws.service
systemctl restart ws.service

# Installing Service
cat > /etc/systemd/system/ws-ovpn.service << END
[Unit]
Description=OpenVPN
Documentation=https://google.com
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/ws-ovpn 2086
Restart=on-failure

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable ws-ovpn
systemctl start ws-ovpn
systemctl restart ws-ovpn
}

function epro(){

if [[ ! -d "/ws" ]]; then
mkdir -p /ws
fi

wget -q -O /ws/ws "${repo}/ws/ws"

echo "## verbose level 0=info, 1=verbose, 2=very verbose
verbose: 0
listen:

# // OpenVPN 
- target_host: 127.0.0.1
  target_port: 1194
  listen_port: 10012

# // DROPBEAR 
- target_host: 127.0.0.1
  target_port: 143
  listen_port: 10015
" > /ws/ws.conf

# Installing Service
cat > /etc/systemd/system/ws.service << END
[Unit]
Description=Websocket
Documentation=https://google.com
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/ws/ws -f /ws/ws.conf
Restart=on-failure

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable ws.service
systemctl start ws.service
systemctl restart ws.service
}

function cekos(){
  source /etc/os-release
  echo "$ID $VERSION_ID"
}

os=$(cekos)

if [[ $os == "ubuntu 20.04" ]]; then
epro
elif [[ $os == "ubuntu 24.04" ]]; then
wspy
elif [[ $os == "debian 10" ]]; then
epro
elif [[ $os == "debian 12" ]]; then
wspy
else
wspy
fi

rm -f $0