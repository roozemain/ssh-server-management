#! /usr/bin/env bash

if [ $(id -u) -eq 0 ]; then
  read -p "Enter username : " username
  userdel "$username"
  [ $? -eq 0 ] && echo "🖥️ The user has been removed successfully! ✅" || echo "🖥️ Cannot find the user! ❌"
  while true; do
    read -p "🖥️ Do you want to delete the user home directory and mailbox? (yes or no):" yn
    case $yn in
    [Yy]*)
      rm -r /home/$username
      rm -r /var/spool/mail/$username
      echo "❤️ Have fun! ❤️"
      break
      ;;
    [Nn]*)
      echo "❤️ Have fun! ❤️"
      break
      ;;
    *) echo "🖥️ Only YES[Yy] or No[Nn] is accepted." ;;
    esac
  done
else
  echo "🤷‍♂️ Only root can run this script! 🤷‍♂️"
  exit 2
fi
