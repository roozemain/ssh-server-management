#! /usr/bin/env bash

if ! [ -f "$FILE" ]; then
	tee adduser-batch.sh << EOF
#! /usr/bin/env bash

EOF
fi

read -p "Enter username : " username
read -p "Enter password : " password
pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
printf "\nuseradd -m -p \"$pass\" \"$username\"\n" >>adduser-batch.sh
printf "\n🖥️ User has been added to adduser-batch file! ✅\n"
