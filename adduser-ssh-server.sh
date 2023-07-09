#! /usr/bin/env bash

if [ $(id -u) -eq 0 ]; then
  read -p "Enter username : " username
  read -s -p "Enter password : " password
  egrep "^$username" /etc/passwd >/dev/null
  if [ $? -eq 0 ]; then
    echo "$username exists!"
    exit 1
  else
    pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
    useradd -m -p "$pass" "$username"
    [ $? -eq 0 ] && printf "\n🖥️ User has been added to system! ✅\n" || printf "\n🖥️ Failed to add a user! ❌\n"
  fi
else
  echo "🤷‍♂️ Only root can run this script! 🤷‍♂️"
  exit 2
fi
