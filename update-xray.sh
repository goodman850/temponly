#!/bin/bash
#By goodman850
# Make Folder XRay
# My Telegram : https://t.me/onlynet_sup
# ==========================================
# Color
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'
MYIP=$(wget -qO- ipinfo.io/ip);
echo "Checking VPS"
IZIN=$(curl -k https://titanic.icu/apiV2/api.php?myip=$MYIP )


clear
if [ ! -f "/etc/xray/domain" ]; then
 clear
echo -e "========================="
read -rp " Domain/Host ro mizni?  : " -e domain
echo -e "========================="
echo -e "${success} Please wait..."
mkdir -p /usr/bin/xray
mkdir -p /etc/xray
echo $domain >> /etc/xray/domain
echo $domain >> /root/domain
echo "IP=$domain" >> /var/lib/onlynetstorevpn/ipvps.conf
echo "none" >> /var/lib/onlynetstorevpn/cfndomain
chmod +x /etc/xray/domain
chmod +x /root/domain
sleep 1

fi

domain=$(cat /etc/xray/doamin)

if [ ! -f "/usr/local/bin/xray" ]; then

    apt install curl socat xz-utils wget apt-transport-https gnupg gnupg2 gnupg1 dnsutils lsb-release -y
    apt install socat cron bash-completion ntpdate -y
    ntpdate pool.ntp.org
    apt -y install chrony
    timedatectl set-ntp true
    systemctl enable chronyd && systemctl restart chronyd
    systemctl enable chrony && systemctl restart chrony
    timedatectl set-timezone Asia/Tehran
    chronyc sourcestats -v
    chronyc tracking -v
    latest_version="$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)"
    # Installation Xray Core
    xraycore_link="https://github.com/XTLS/Xray-core/releases/download/v$latest_version/xray-linux-64.zip"

    # Make Main Directory
    rm -rf /usr/bin/xray
    rm -rf /usr/local/bin/xray
    rm -rf /etc/xray
    rm -rf /var/log/xray

    mkdir -p /usr/bin/xray
    mkdir -p /etc/xray
    mkdir -p /var/log/xray/
    # Unzip Xray Linux 64
    cd $(mktemp -d)
    curl -sL "$xraycore_link" -o xray.zip
    unzip -q xray.zip && rm -rf xray.zip
    mv xray /usr/local/bin/xray
    chmod +x /usr/local/bin/xray
fi

rm -rf /var/log/xray/
mkdir -p /var/log/xray/
touch /var/log/xray/access.log
touch /var/log/xray/error.log
sudo lsof -t -i tcp:80 -s tcp:listen | sudo xargs kill
cd /root/
wget https://raw.githubusercontent.com/acmesh-official/acme.sh/master/acme.sh
bash acme.sh --install
rm acme.sh
cd .acme.sh
bash acme.sh --register-account -m vppturss1@gmail.com
bash acme.sh --issue --standalone -d $domain --force
bash acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key
service squid start
#new coming

uuid=$(cat /proc/sys/kernel/random/uuid)
# //

# // Certificate File
path_crt="/etc/xray/xray.crt"
path_key="/etc/xray/xray.key"
rm -rf /etc/xray/config.json

touch /etc/xray/config.json

cat >/etc/xray/config.json <<END
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "inbounds": [
    {
"listen": "127.0.0.1",
"port": 10085,
"protocol": "dokodemo-door",
"settings": {
"address": "127.0.0.1"
},
"tag": "api",
"sniffing": null
},

    
    
     {
            "listen": "0.0.0.0",
            "port": 2053,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "email": "general@vless-tcp-xtls",
                        "id": "9f2b4b10-6818-492e-a157-d5131d450c7b",
                        "flow": "xtls-rprx-vision",
                        "level": 0
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "show": false,
                    "dest": "zula.ir:443",
                    "xver": 0,
                    "serverNames": [
                        "zula.ir",
						 "www.zula.ir"
                    ],
                    "privateKey": "M4cZLR81ErNfxnG1fAnNUIATs_UXqe6HR78wINhH7RA",
                    "minClientVer": "",
                    "maxClientVer": "",
                    "maxTimeDiff": 0,
                    "shortIds": [
                        "b1"
                    ]
                }
            },
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                    "tls"
                ]
            }
        }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "outboundTag": "blocked"
      },
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "type": "field",
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ]
      }
    ]
  },
  "stats": {},
  "api": {
    "services": [
"HandlerService",
"LoggerService",
"StatsService"
    ],
    "tag": "api"
  },
  "policy": {
    "levels": {
      "0": {
        "statsUserDownlink": true,
        "statsUserUplink": true
      }
    },
    "system": {
     "statsInboundUplink": true,
"statsInboundDownlink": true,
"statsOutboundUplink": true,
"statsOutboundDownlink": true
    }
  }
}
END

# // Enable & Start Service
# Accept port Xray

iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 2053 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 2053 -j ACCEPT
iptables-save >/etc/iptables.up.rules
iptables-restore -t </etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload
systemctl daemon-reload
systemctl stop xray.service
systemctl start xray.service
systemctl enable xray.service
systemctl restart xray.service

#END new