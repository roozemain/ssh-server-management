#! /usr/bin/env bash
# Author: rozemyneroozemain@gmail.com

known_compatible_distros=(
  "Ubuntu"
  "Debian"
  "CentOS"
  "Fedora"
  "Red Hat"
)

function detect_distro_phase1() {

  for i in "${known_compatible_distros[@]}"; do
    uname -a | grep "${i}" -i >/dev/null
    if [ "$?" = "0" ]; then
      DISTRO="${i^}"
      break
    fi
  done
}

function detect_distro_phase2() {

  if [ "${DISTRO}" = "Unknown Linux" ]; then
    if [ -f ${osversionfile_dir}"centos-release" ]; then
      DISTRO="CentOS"
    elif [ -f ${osversionfile_dir}"fedora-release" ]; then
      DISTRO="Fedora"
    elif [ -f ${osversionfile_dir}"redhat-release" ]; then
      DISTRO="Red Hat"
    elif [ -f ${osversionfile_dir}"debian_version" ]; then
      DISTRO="Debian"
    fi
  fi
}

detect_distro_phase1
detect_distro_phase2

main_interface=$(ip route get 8.8.8.8 | awk -- '{printf $5}')

echo "🚀 Welcome to your SSH Server with multipleports 🚀"
if [ $(id -u) -eq 0 ]; then
  if [[ "$DISTRO" == "Debian" ]] || [[ "$DISTRO" == "Ubuntu" ]]; then
    echo "🔍 update source repository 🔎"
    apt update
  elif [[ "$DISTRO" == "Fedora" ]] || [[ "$DISTRO" == "Red Hat" ]] || [[ "$DISTRO" == "Centos" ]]; then
    echo "🔍 update source repository 🔎"
    yum update
    echo "🤷‍♂️ This script only support iptables! 🤷‍♂️"
    while true; do
      read -p "📉 Do you want to delete firewalld and install iptables? (yes or no):" yn
      case $yn in
      [Yy]*)
        yum remove firewalld
        yum install iptables iptables-services
        service iptables save
        systemctl enable iptables
        echo "📉 iptables now available 📉"
        break
        ;;
      [Nn]*)
        echo "❤️ Have fun! You can create a pull request for this feature! ❤️"
        exit
        ;;
      *) echo "📉 Only YES[Yy] or No[Nn] is accepted." ;;
      esac
    done
    yum install iptables-persistent -y
  else
    echo "🥹 Oops! cannot support this operation system, sorry. 🥹"
    exit 1
  fi
  echo "📔 config your iptables 📔"

  default_ssh_port_number=22

  while true; do
    read -p "Enter SSH port number (Press enter to use default port 22): " ssh_port_number
    ssh_port_number=${ssh_port_number:-$default_ssh_port_number}

    if [[ "$ssh_port_number" =~ ^[0-9]+$ ]] && [ "$ssh_port_number" -le 9999 ]
    then
      break
    else
      echo "Error: Invalid port number. Please enter a number less than 10000."
    fi
  done

  iptables -t nat -A PREROUTING -i $main_interface -p tcp --dport 10000:39999 -j REDIRECT --to-port $ssh_port_number
  ip6tables -t nat -A PREROUTING -i $main_interface -p tcp --dport 10000:39999 -j REDIRECT --to-port $ssh_port_number

  while true; do
    read -p "📉 Do you want to apply the iptables changes or not? (yes or no):" yn
    case $yn in
    [Yy]*)
      ## IPV4
      sudo /sbin/iptables-save >/etc/iptables/rules.v4
      ## IPv6 ##
      sudo /sbin/ip6tables-save >/etc/iptables/rules.v6
      apt install iptables-persistent -y
      echo "📉 The changes have been applied successfully. 📉"
      break
      ;;
    [Nn]*)
      echo "📉 Whenever you need to apply iptables changes, you can easily execute the setiptables.sh file in your root directory. 📉"
      exit
      ;;
    *) echo "📉 Only YES[Yy] or No[Nn] is accepted." ;;
    esac
  done
  echo "📉 download badvpn-udpgw for add udp support 📉"
  wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/daybreakersx/premscript/master/badvpn-udpgw64"
  echo "📉 add badvpn config to your rc file 📉"
  printf "#! /bin/sh -e\nscreen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300\nexit 0\n" >>/etc/rc.local
  echo "🗂️ add execute permission to your rc file and udpgw file. 🗂️"
  chmod +x /etc/rc.local
  chmod +x /usr/bin/badvpn-udpgw
  echo "🚀 run badvpn-udpgw with default port. 🚀"
  sudo screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300
  echo "📉 add iptables config to your crontab root file. 📉"
  printf "#! /bin/sh\nmain_interface=$(ip route get 8.8.8.8 | awk -- '{printf $5}')\niptables -t nat -A PREROUTING -i $main_interface -p tcp --dport 10000:39999 -j REDIRECT --to-port $ssh_port_number\nip6tables -t nat -A PREROUTING -i $main_interface -p tcp --dport 10000:39999 -j REDIRECT --to-port $ssh_port_number\necho \"🚀 load iptables set! 🚀\"\nexit 0\n" >/root/setiptables.sh
  chmod +x /root/setiptables.sh && echo "@reboot sh /root/setiptables.sh" >>/var/spool/cron/root
  crontab /var/spool/cron/root && crontab -u root -l && sudo lsof -i -P -n | grep LISTEN
  exit 0
else
  echo "🤷‍♂️ Only root can run this script! 🤷‍♂️"
  exit 1
fi
