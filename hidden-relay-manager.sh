#!/bin/bash

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

function installing-system-requirements() {
  # shellcheck disable=SC2233,SC2050
  if { [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "pop" ] || [ "$DISTRO" == "kali" ]; }; then
    apt-get update && apt-get install curl bc jq -y
    # shellcheck disable=SC2233,SC2050
  elif { [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "centos" ] || [ "DISTRO" == "rhel" ]; }; then
    yum update -y && yum install epel-release curl bc jq -y
  elif [ "$DISTRO" == "arch" ]; then
    pacman -Syu --noconfirm curl bc jq
  fi
}

# Run the function and check for requirements
installing-system-requirements

# ask the user what to install
function what-to-install() {
  echo "What would you like to install?"
  echo "  1) Relay (Recommended)"
  echo "  2) Bridge"
  echo "  3) Exit Node (Advanced)"
  until [[ "$INSTALLER_COICE_SETTINGS" =~ ^[1-3]$ ]]; do
    read -rp "Installer Choice [1-3]: " -e -i 1 INSTALLER_COICE_SETTINGS
  done
  # Apply port response
  case $INSTALLER_COICE_SETTINGS in
  1)
    INSTALLER_COICE="y INSTALL_RELAY"
    ;;
  2)
    INSTALLER_COICE="y INSTALL_BRIDGE"
    ;;
  3)
    INSTALLER_COICE="y INSTALL_EXIT_NODE"
    ;;
  esac
}

# ask the user what to install
what-to-install

function contact-info() {
  echo "What contact info would you like to use?"
  echo "  1) John Doe (Recommended)"
  echo "  2) Custom (Advanced)"
  until [[ "$CONTACT_INFO_SETTINGS" =~ ^[1-3]$ ]]; do
    read -rp "ipv4 choice [1-3]: " -e -i 1 CONTACT_INFO_SETTINGS
  done
  # Apply port response
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
}

contact-info

# Question 1: Determine host port
function set-port() {
  echo "Do u want to use the recommened ports?"
  echo "   1) Yes (Recommended)"
  echo "   2) Custom (Advanced)"
  until [[ "$PORT_CHOICE_SETTINGS" =~ ^[1-2]$ ]]; do
    read -rp "Port choice [1-2]: " -e -i 1 PORT_CHOICE_SETTINGS
  done
  # Apply port response
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
}

# Set the port number
set-port

# Determine host port
function test-connectivity-v4() {
  echo "How would you like to detect IPV4?"
  echo "  1) Curl (Recommended)"
  echo "  2) IP (Advanced)"
  echo "  3) Custom (Advanced)"
  until [[ "$SERVER_HOST_V4_SETTINGS" =~ ^[1-3]$ ]]; do
    read -rp "ipv4 choice [1-3]: " -e -i 1 SERVER_HOST_V4_SETTINGS
  done
  # Apply port response
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
}

# Set Port
test-connectivity-v4

# Determine ipv6
function test-connectivity-v6() {
  echo "How would you like to detect IPV6?"
  echo "  1) Curl (Recommended)"
  echo "  2) IP (Advanced)"
  echo "  3) Custom (Advanced)"
  until [[ "$SERVER_HOST_V6_SETTINGS" =~ ^[1-3]$ ]]; do
    read -rp "ipv6 choice [1-3]: " -e -i 1 SERVER_HOST_V6_SETTINGS
  done
  # Apply port response
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
}

# Set Port
test-connectivity-v6

# Install Tor
function install-tor() {
  if [ "$INSTALL_RELAY" = "y" ]; then
    if ([ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ]); then
      apt-get update
      apt-get install ntpdate tor nyx unbound -y
    elif [ "$DISTRO" = "fedora" ]; then
      dnf update -y
    elif ([ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ]); then
      yum update -y
      yum install epel-release -y
      yum install unbound -y
    fi
    # unbound
    chattr -i /etc/resolv.conf
    sed -i "s|nameserver|#nameserver|" /etc/resolv.conf
    sed -i "s|search|#search|" /etc/resolv.conf
    echo "nameserver 127.0.0.1" >>/etc/resolv.conf
    chattr +i /etc/resolv.conf
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
  if [ "$INSTALL_BRIDGE" = "y" ]; then
    if ([ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ]); then
      apt-get update
      apt-get install ntpdate tor nyx obfs4proxy -y
    elif [ "$DISTRO" = "fedora" ]; then
      dnf update -y
    elif ([ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ]); then
      yum update -y
      yum install epel-release -y
    fi
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
  if [ "$INSTALL_EXIT_NODE" = "y" ]; then
    if ([ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ]); then
      apt-get update
      apt-get install ntpdate tor nyx unbound -y
    elif [ "$DISTRO" = "fedora" ]; then
      dnf update -y
    elif ([ "$DISTRO" == "centos" ] || [ "$DISTRO" == "rhel" ]); then
      yum update -y
      yum install epel-release tor nyx unbound -y
    fi
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
  if ([ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ] || [ "$DISTRO" == "raspbian" ] || [ "$DISTRO" == "centos" ] || [ "$DISTRO" == "fedora" ] || [ "$DISTRO" == "rhel" ]); then
    ntpdate pool.ntp.org
  fi
}

# Install Tor
install-tor

# enable and than restart the defualt tor service
function restart-service() {
  if pgrep systemd-journal; then
    # tor
    systemctl enable tor@default
    systemctl restart tor@default
    # nyx
    systemctl enable nyx
    systemctl restart nyx
  else
    # tor
    service tor@default enable
    service tor@default restart
    # nyx
    service nyx enable
    service nyx restart
  fi
}

# enable and than restart the defualt tor service
restart-service
