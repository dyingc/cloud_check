#!/bin/sh

IP_LIST_DIR=subs
today=`date '+%F'`
IP_LIST_FILE="Public IP Addresses"

find "${IP_LIST_DIR}" -type f -name "${IP_LIST_FILE}" | grep "/${today}/" | while read f
do
	sub=${f#subs*/}
	sub=${sub%%/*}
	echo ${sub}
	cat "${f}" | jq '. | {ipAddress}' | grep 'ipAddress' | awk -F'"' '{print $4}' | grep -v '^$' | while read pubip
	do
		echo "\t"$pubip
	done
done
