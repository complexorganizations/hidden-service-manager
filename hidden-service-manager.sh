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
HIDDEN_SERVICE_MANAGER_UPDATE="https://raw.githubusercontent.com/complexorganizations/hidden-service-manager/main/hidden-service-manager.sh"

# Verify that it is an old installation or another installer
function previous-tor-installation() {
  if [ -d "$TOR_PATH" ]; then
    if [ ! -f "$HIDDEN_SERVICE_MANAGER" ]; then
      rm -rf $TOR_PATH
    fi
  fi
}

# Run the function to eliminate old installation or another installer
# previous-tor-installation

if [ ! -f "$TOR_TORRC" ]; then

  function install-service() {
    if ! [ -x "$(command -v tor)" ]; then
      if { [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "pop" ] || [ "$DISTRO" == "kali" ]; }; then
        apt-get update
        apt-get install ntpdate tor nyx nginx -y
      elif { [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ]; }; then
        yum update
        yun install ntp tor nyx nginx -y
      elif { [ "$DISTRO" == "arch" ] || [ "$DISTRO" == "manjaro" ]; }; then
        pacman -Syu
        pacman -Syu --noconfirm tor ntp nginx
      elif [ "$DISTRO" == "alpine" ]; then
        apk update
        apk add tor ntp nginx
      fi
    fi
  }

  install-service

function secure-firewall() {
  # Install Firwall
  if { [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "pop" ] || [ "$DISTRO" == "kali" ]; }; then
    apt-get update
    apt-get install ufw fail2ban -y
  elif { [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ]; }; then
    yum install ufw -y
  elif { [ "$DISTRO" == "arch" ] || [ "$DISTRO" == "manjaro" ]; }; then
    pacman -Syu --noconfirm ufw fail2ban
  elif [ "$DISTRO" == "alpine" ]; then
    apk install ufw fail2ban
  fi
  # Configure UFW
  if [ -x "$(command -v ufw)" ]; then
    ufw allow 80/tcp
  fi
  # Secure Nginx
  if [ -x "$(command -v nginx)" ]; then
    sed -i "s|# server_tokens off;|server_tokens off;|" /etc/nginx/nginx.conf
    chmod 700 /var/www/html/
  fi
  # Fail2ban
  if [ ! -f "/etc/fail2ban/jail.conf" ]; then
    sed -i "s|# bantime = 1h|bantime = 720h|" /etc/fail2ban/jail.conf
    sed -i "s|# enabled = true|enabled = true|" /etc/fail2ban/jail.conf
  fi
}

function configure-nginx() {
  # Secure Nginx
  if [ -x "$(command -v nginx)" ]; then
    sed -i "s|listen 80 default_server;|listen 8080 default_server;|" /etc/nginx/sites-enabled/default
    sed -i "s|listen [::]:80 default_server;|listen [::]:8080 default_server;|" /etc/nginx/sites-enabled/default
    sed -i "s|#HiddenServiceDir /var/lib/tor/hidden_service/|HiddenServiceDir /var/lib/tor/hidden_service/|" /etc/tor/torrc
    sed -i "s|#HiddenServicePort 80 127.0.0.1:80|HiddenServicePort 80 127.0.0.1:8080|" /etc/tor/torrc
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
  }
  
  restart-service
  
  HOSTNAME=$(cat /var/lib/tor/hidden_service/hostname)
  echo "Your Hostname: $HOSTNAME"

else

## Update, Security...

fi
