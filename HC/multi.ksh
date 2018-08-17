#!/bin/bash
# To automate repeatable DBA tasks.
# Version 1.0 by Thiago Cargnelutti - 2013/09/16
# Version 2.0 by Thiago Cargnelutti - 2014/01/10
# Version 3.0 by Thiago Cargnelutti - 2014/04/04

read -p "Please input the personal id: " ID
read -p "Please input the personal id password: " -s password

while read server; do
	echo ""
	echo ""
	echo ". Starting job for server $server."
if [[ $2 -eq 0 ]] ; then
		./autospreadchanges.exp $server $ID $password $password $2 $3 | tee output.$server.$ID
else
		./autospreadchanges.exp $server $ID $password $password $2 $3 $4 $5 $6 $7| tee output.$server.$ID
fi
done < $1
