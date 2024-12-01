#!/bin/bash
rm -f $0
# ==========================================
# Color
NC='\033[0m'
GREEN='\033[0;32m'
# ==========================================
user=$(curl -s https://raw.githubusercontent.com/kipasu/ip/main/x | base64 -d)
REPO="https://raw.githubusercontent.com/${user}/f/main/"
cd
sleep 0.5
echo -e "[ ${green}INFO${NC} ] Checking... "
apt install iptables iptables-persistent -y
sleep 0.5
echo -e "[ ${green}INFO$NC ] Setting ntpdate"
ntpdate pool.ntp.org
timedatectl set-ntp true
sleep 0.5
echo -e "[ ${green}INFO$NC ] Enable chrony"
systemctl enable chrony
systemctl restart chrony
timedatectl set-timezone Asia/Jakarta
sleep 0.5
echo -e "[ ${green}INFO$NC ] Setting chrony tracking"
chronyc sourcestats -v
chronyc tracking -v
echo -e "[ ${green}INFO$NC ] Setting dll"
apt clean all && apt update
apt install curl socat xz-utils wget apt-transport-https gnupg gnupg2 gnupg1 dnsutils lsb-release -y
apt install socat cron bash-completion ntpdate -y
ntpdate pool.ntp.org
apt -y install chrony
apt install zip -y
apt install curl pwgen openssl cron -y

# install xray
sleep 0.5
echo -e "[ ${green}INFO$NC ] Downloading & Installing xray core"
domainSock_dir="/run/xray";! [ -d $domainSock_dir ] && mkdir  $domainSock_dir
chown www-data.www-data $domainSock_dir
# Make Folder XRay
mkdir -p /var/log/xray
mkdir -p /etc/xray
chown www-data.www-data /var/log/xray
chmod +x /var/log/xray
touch /var/log/xray/{access1.log,error1.log,access2.log,error2.log,access3.log,error3.log,access4.log,error4.log}
# / / Ambil Xray Core Version Terbaru
latest_version="$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data --version $latest_version

uuid=$(cat /proc/sys/kernel/random/uuid)

## crt xray
systemctl stop nginx
#systemctl stop haproxy
domain=$(cat /etc/xray/domain)
mkdir /root/.acme.sh
curl https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
chmod +x /root/.acme.sh/acme.sh
/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc

# nginx renew ssl
echo -n '#!/bin/bash
/etc/init.d/nginx stop
"/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" &> /root/renew_ssl.log
/etc/init.d/nginx start
/etc/init.d/nginx status
' > /usr/local/bin/ssl_renew.sh
chmod +x /usr/local/bin/ssl_renew.sh
if ! grep -q 'ssl_renew.sh' /var/spool/cron/crontabs/root;then (crontab -l;echo "15 03 */3 * * /usr/local/bin/ssl_renew.sh") | crontab;fi

mkdir -p /var/www/html
cd /etc/xray
wget -q -O xray.zip "${REPO}xray/xray.zip"
unzip xray.zip
mv runn.service /etc/systemd/system
mv xray.conf /etc/nginx/conf.d/xray.conf
rm -r xray.zip
cd
sed -i "s/xxx/${uuid}/g" /etc/xray/*.json
sed -i 's/xxx/$domain/' /etc/nginx/conf.d/xray.conf

wget -q -O /usr/local/share/xray/geosite.dat "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat" >/dev/null 2>&1
wget -q -O /usr/local/share/xray/geoip.dat "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat" >/dev/null 2>&1

# Function to create service
create_service() {
    local name=$1
    local description=$2
    local exec_start=$3

    cat >/etc/systemd/system/config@${name}.service <<EOF
[Unit]
Description=${description} %i
Documentation=https://t.me/kipasu
After=network.target nss-lookup.target

[Service]
User=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=yes
ExecStart=${exec_start}
Restart=on-failure
LimitNPROC=10000

[Install]
WantedBy=multi-user.target
EOF
}

# Create services for vmess, vless, trojan, and shadowsocks
create_service "vmess" "XDTunnel Service Xray" "/usr/local/bin/xray run -config /etc/xray/%i.json"
create_service "vless" "XDTunnel Service Xray" "/usr/local/bin/xray run -config /etc/xray/%i.json"
create_service "trojan" "XDTunnel Service Xray" "/usr/local/bin/xray run -config /etc/xray/%i.json"
create_service "ss" "XDTunnel Service Xray" "/usr/local/bin/xray run -config /etc/xray/%i.json"

# Create additional configuration file for xray
cat >/etc/systemd/system/xray@.service.d/10-donot_touch_single_conf.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/local/bin/xray run -config /etc/xray/%i.json
EOF

echo -e "$yell[SERVICE]$NC Restart All service"
systemctl daemon-reload
sleep 0.5
echo -e "[ ${green}ok${NC} ] Enable & restart xray "
systemctl daemon-reload
systemctl enable config@{vmess,vless,trojan,ss} >/dev/null 2>&1
systemctl restart config@{vmess,vless,trojan,ss} >/dev/null 2>&1
systemctl restart nginx >/dev/null 2>&1
systemctl enable runn >/dev/null 2>&1
systemctl restart runn >/dev/null 2>&1

sleep 0.5
clear
