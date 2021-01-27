#!/bin/bash
# https://github.com/complexorganizations/hidden-service-manager

# Require script to be run as root
function super-user-check() {
  if [ "$EUID" -ne 0 ]; then
    echo "You need to run this script as super user."
    exit
  fi
}

# Check for root
super-user-check

# Detect Operating System
function dist-check() {
  if [ -e /etc/os-release ]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    DISTRO=$ID
    DISTRO_VERSION=$VERSION_ID
  fi
}

# Check Operating System
dist-check

# Pre-Checks system requirements
function installing-system-requirements() {
  if { [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "pop" ] || [ "$DISTRO" == "kali" ] || [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ] || [ "$DISTRO" == "arch" ] || [ "$DISTRO" == "manjaro" ] || [ "$DISTRO" == "alpine" ]; }; then
    if { ! [ -x "$(command -v curl)" ] || ! [ -x "$(command -v iptables)" ] || ! [ -x "$(command -v bc)" ] || ! [ -x "$(command -v jq)" ] || ! [ -x "$(command -v sed)" ] || ! [ -x "$(command -v zip)" ] || ! [ -x "$(command -v unzip)" ] || ! [ -x "$(command -v grep)" ] || ! [ -x "$(command -v awk)" ] || ! [ -x "$(command -v ip)" ]; }; then
      if { [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "pop" ] || [ "$DISTRO" == "kali" ]; }; then
        apt-get update && apt-get install iptables curl coreutils bc jq sed e2fsprogs zip unzip grep gawk iproute2 -y
      elif { [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ]; }; then
        yum update -y && yum install epel-release iptables curl coreutils bc jq sed e2fsprogs zip unzip grep gawk iproute2 -y
      elif { [ "$DISTRO" == "arch" ] || [ "$DISTRO" == "manjaro" ]; }; then
        pacman -Syu --noconfirm iptables curl bc jq sed zip unzip grep gawk iproute2
      elif [ "$DISTRO" == "alpine" ]; then
        apk update && apk add iptables curl bc jq sed zip unzip grep gawk iproute2
      fi
    fi
  else
    echo "Error: $DISTRO not supported."
    exit
  fi
}

# Run the function and check for requirements
installing-system-requirements

# Global variables
TOR_PATH="/etc/tor"
TOR_TORRC="$TOR_PATH/torrc"
HIDDEN_SERVICE_MANAGER="$TOR_PATH/hidden-service-manager"
TOR_HIDDEN_SERVICE="$TOR_PATH/hidden-service-manager"
HIDDEN_SERVICE_MANAGER_UPDATE="https://raw.githubusercontent.com/complexorganizations/hidden-service-manager/main/hidden-service-manager.sh"
NGINX_GLOBAL_CONFIG="/etc/nginx/nginx.conf"
FAIL_TO_BAN_CONFIG="/etc/fail2ban/jail.conf"

# ask the user what to install
function choose-hidden-service() {
  if [ ! -f "$HIDDEN_SERVICE_MANAGER" ]; then
  echo "What would you like to install?"
  echo "  1) TOR (Recommended)"
  until [[ "$HIDDEN_SERVICE_CHOICE_SETTINGS" =~ ^[1-1]$ ]]; do
    read -rp "Installer Choice [1-4]: " -e -i 1 HIDDEN_SERVICE_CHOICE_SETTINGS
  done
  # Apply port response
  case $HIDDEN_SERVICE_CHOICE_SETTINGS in
  1)
    if [ -f "$TOR_PATH" ]; then
      rm -f $TOR_PATH
    fi
    echo "TOR: true" >>$TOR_HIDDEN_SERVICE
    ;;
  esac
  fi
}

# ask the user what to install
choose-hidden-service

# ask the user what to install
function what-to-install() {
if [ -f "$TOR_HIDDEN_SERVICE" ]; then
  echo "What would you like to install?"
  echo "  1) Hidden Service (Recommended)"
  echo "  2) Relay"
  echo "  3) Bridge"
  echo "  4) Exit Node (Advanced)"
  until [[ "$INSTALLER_COICE_SETTINGS" =~ ^[1-4]$ ]]; do
    read -rp "Installer Choice [1-4]: " -e -i 1 INSTALLER_COICE_SETTINGS
  done
  # Apply port response
  case $INSTALLER_COICE_SETTINGS in
  1)
    echo "1"
    ;;
  2)
    echo "2"
    ;;
  3)
    echo "3"
    ;;
  4)
    echo "4"
    ;;
  esac
fi
}

# ask the user what to install
what-to-install

function contact-info() {
if [ -f "$TOR_HIDDEN_SERVICE" ]; then
  echo "What contact info would you like to use?"
  echo "  1) John Doe (Recommended)"
  echo "  2) Custom (Advanced)"
  until [[ "$CONTACT_INFO_SETTINGS" =~ ^[1-3]$ ]]; do
    read -rp "Contact Info [1-3]: " -e -i 1 CONTACT_INFO_SETTINGS
  done
  case $CONTACT_INFO_SETTINGS in
  1)
    CONTACT_INFO_NAME="John Doe"
    CONTACT_INFO_EMAIL="johndoe@example.com"
    ;;
  2)
    read -rp "Custom Name: " -e -i "John Doe" CONTACT_INFO_NAME
    read -rp "Custom Email: " -e -i "johndoe@example.com" CONTACT_INFO_EMAIL
    ;;
  esac
fi
}

contact-info

# Question 1: Determine host port
function set-port() {
if [ -f "$TOR_HIDDEN_SERVICE" ]; then
  echo "Do u want to use the recommened ports?"
  echo "   1) Yes (Recommended)"
  echo "   2) Custom (Advanced)"
  until [[ "$PORT_CHOICE_SETTINGS" =~ ^[1-2]$ ]]; do
    read -rp "Port choice [1-2]: " -e -i 1 PORT_CHOICE_SETTINGS
  done
  case $PORT_CHOICE_SETTINGS in
  1)
    OR_SERVER_PORT="9001"
    DIR_SERVER_PORT="9030"
    CON_SERVER_PORT="9051"
    ;;
  2)
    read -rp "Custom OR Port" -e -i "9001" OR_SERVER_PORT
    read -rp "Custom DIR Port" -e -i "9030" DIR_SERVER_PORT
    read -rp "Custom CON Port" -e -i "9051" CON_SERVER_PORT
    ;;
  esac
fi
}

# Set the port number
set-port

# Determine host port
function test-connectivity-v4() {
if [ -f "$TOR_HIDDEN_SERVICE" ]; then
  echo "How would you like to detect IPV4?"
  echo "  1) Curl (Recommended)"
  echo "  2) IP (Advanced)"
  echo "  3) Custom (Advanced)"
  until [[ "$SERVER_HOST_V4_SETTINGS" =~ ^[1-3]$ ]]; do
    read -rp "ipv4 choice [1-3]: " -e -i 1 SERVER_HOST_V4_SETTINGS
  done
  case $SERVER_HOST_V4_SETTINGS in
  1)
    SERVER_HOST_V4="$(curl -4 -s 'https://api.ipengine.dev' | jq -r '.network.ip')"
    ;;
  2)
    SERVER_HOST_V4=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
    ;;
  3)
    read -rp "Custom IPV4: " -e -i "$(curl -4 -s 'https://api.ipengine.dev' | jq -r '.network.ip')" SERVER_HOST_V4
    ;;
  esac
fi
}

# Set Port
test-connectivity-v4

# Determine ipv6
function test-connectivity-v6() {
if [ -f "$TOR_HIDDEN_SERVICE" ]; then
  echo "How would you like to detect IPV6?"
  echo "  1) Curl (Recommended)"
  echo "  2) IP (Advanced)"
  echo "  3) Custom (Advanced)"
  until [[ "$SERVER_HOST_V6_SETTINGS" =~ ^[1-3]$ ]]; do
    read -rp "ipv6 choice [1-3]: " -e -i 1 SERVER_HOST_V6_SETTINGS
  done
  case $SERVER_HOST_V6_SETTINGS in
  1)
    SERVER_HOST_V6="$(curl -6 -s 'https://api.ipengine.dev' | jq -r '.network.ip')"
    ;;
  2)
    SERVER_HOST_V6=$(ip r get to 2001:4860:4860::8888 | perl -ne '/src ([\w:]+)/ && print "$1\n"')
    ;;
  3)
    read -rp "Custom IPV6: " -e -i "$(curl -6 -s 'https://api.ipengine.dev' | jq -r '.network.ip')" SERVER_HOST_V6
    ;;
  esac
fi
}

# Set Port
test-connectivity-v6

# Install Tor
function install-tor() {
if [ -f "$TOR_HIDDEN_SERVICE" ]; then
  if ! [ -x "$(command -v tor)" ]; then
    if { [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "pop" ] || [ "$DISTRO" == "kali" ]; }; then
      apt-get update
      apt-get install ntpdate tor nyx -y
    elif { [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ]; }; then
      yum update
      yun install ntp tor nyx -y
    elif { [ "$DISTRO" == "arch" ] || [ "$DISTRO" == "manjaro" ]; }; then
      pacman -Syu
      pacman -Syu --noconfirm tor ntp
    elif [ "$DISTRO" == "alpine" ]; then
      apk update
      apk add tor ntp
    fi
  fi
fi
}

# Install Tor
install-tor

function install-unbound() {
if [ -f "$TOR_HIDDEN_SERVICE" ]; then
  if ! [ -x "$(command -v unbound)" ]; then
    if { [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "pop" ] || [ "$DISTRO" == "kali" ]; }; then
      apt-get update
      apt-get install unbound -y
    elif { [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ]; }; then
      yum update
      yun install unbound  -y
    elif { [ "$DISTRO" == "arch" ] || [ "$DISTRO" == "manjaro" ]; }; then
      pacman -Syu
      pacman -Syu --noconfirm unbound
    elif [ "$DISTRO" == "alpine" ]; then
      apk update
      apk add unbound
    fi
  fi
fi
}

install-unbound

if [ -x "$(command -v ntp)" ]; then	
  ntpdate pool.ntp.org	
fi

function hidden-service-config() {
if [ -f "$TOR_HIDDEN_SERVICE" ]; then
    if [ -x "$(command -v nginx)" ]; then
      sed -i "s|listen 80 default_server;|listen 8080 default_server;|" /etc/nginx/sites-enabled/default
      sed -i "s|listen [::]:80 default_server;|listen [::]:8080 default_server;|" /etc/nginx/sites-enabled/default
      sed -i "s|#HiddenServiceDir /var/lib/tor/hidden_service/|HiddenServiceDir /var/lib/tor/hidden_service/|" /etc/tor/torrc
      sed -i "s|#HiddenServicePort 80 127.0.0.1:80|HiddenServicePort 80 127.0.0.1:8080|" /etc/tor/torrc
      sed -i "s|# server_tokens off;|server_tokens off;|" $NGINX_GLOBAL_CONFIG	
    fi
fi
}

function bridge-config() {
if [ -f "$TOR_HIDDEN_SERVICE" ]; then
    echo "ORPort auto
ORPort [$SERVER_HOST_V6]:auto
SocksPort 0
BridgeRelay 1
ServerTransportPlugin obfs4 exec /usr/bin/obfs4proxy
ServerTransportListenAddr obfs4 0.0.0.0:8042
ServerTransportListenAddr obfs4 [::]:8042
ExtOrPort auto
Log notice file /var/log/tor/notices.log
ExitPolicy reject6 *:*, reject *:*
DisableDebuggerAttachment 0
ControlPort $CON_SERVER_PORT
CookieAuthentication 1" >>/etc/tor/torrc
fi
}

function relay-config() {
if [ -f "$TOR_HIDDEN_SERVICE" ]; then
    chattr -i /etc/resolv.conf
    sed -i "s|nameserver|#nameserver|" /etc/resolv.conf
    sed -i "s|search|#search|" /etc/resolv.conf
    echo "nameserver 127.0.0.1" >>/etc/resolv.conf
    chattr +i /etc/resolv.conf
    # torrc file
    echo "SocksPort 0
RunAsDaemon 1
ORPort $OR_SERVER_PORT
ORPort [$SERVER_HOST_V6]:$OR_SERVER_PORT
Nickname $CONTACT_INFO_NAME
ContactInfo $CONTACT_INFO_EMAIL
Log notice file /var/log/tor/notices.log
DirPort $DIR_SERVER_PORT
ExitPolicy reject6 *:*, reject *:*
DisableDebuggerAttachment 0
ControlPort $CON_SERVER_PORT
CookieAuthentication 1" >>/etc/tor/torrc
    # enable and restart service
    if pgrep systemd-journal; then
      systemctl enable unbound
      systemctl restart unbound
    else
      service unbound enable
      service unbound restart
    fi
  fi
}

function exit-config() {
if [ -f "$TOR_HIDDEN_SERVICE" ]; then
    echo "SocksPort 0
RunAsDaemon 1
ORPort $OR_SERVER_PORT
ORPort [$SERVER_HOST_V6]:9001
Nickname tt
ContactInfo $CONTACT_INFO_EMAIL
Log notice file /var/log/tor/notices.log
DirPort 80
DirPortFrontPage /etc/tor/tor-exit-notice.html
ExitPolicy accept *:53        # DNS
ExitPolicy accept *:80        # HTTP
ExitPolicy accept *:443       # HTTPS
ExitPolicy reject *:*
IPv6Exit 1
DisableDebuggerAttachment 0
ControlPort 9051
CookieAuthentication 1" >>/etc/tor/torrc
    curl https://raw.githubusercontent.com/torproject/tor/master/contrib/operator-tools/tor-exit-notice.html --create-dirs -o /etc/tor/tor-exit-notice.html
fi
}

  function restart-service() {	
    if pgrep systemd-journal; then	
      # Tor	
      systemctl enable tor	
      systemctl restart tor	
      # Nginx	
      systemctl enable nginx	
      systemctl restart nginx	
      # NTP	
      systemctl enable ntp	
      systemctl restart ntp	
      # fail2ban	
      systemctl enable fail2ban	
      systemctl restart fail2ban	
    else	
      # Tor	
      service tor enable	
      service tor restart	
      # Nginx	
      service nginx enable	
      service nginx restart	
      # NTP	
      service ntp enable	
      service ntp restart	
      # Fail2ban	
      service fail2ban enable	
      service fail2ban restart	
    fi
