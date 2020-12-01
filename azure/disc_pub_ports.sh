#!/bin/sh
SCAN_NUM=2000 # How many top ports are we going to scan

RED='\033[0;31m'
BR='\033[1;31m' # Bold Red
NC='\033[0m' # No color
BO='\033[0;33m' # Brown/Orange
YEL='\033[1;33m' # Yellow
BL='\033[0;34m'  # Blue
LB='\033[1;34m'  # Light Blue

#time nmap -sS --top-ports 50 -oN fast_scan_mbb_tui.nmap -iL hosts-to-scan.lst 
#cat fast_scan_mbb_tui.nmap | head -20 | sed 's#\d\+\.\d\+s#<SomeNum>#'

IP_LIST_DIR=subs
today=`date '+%F'`
IP_LIST_FILE="Public IP Addresses"

function scan_pub_ips() {
	HOSTS_TO_SCAN=$1
	SCAN_RESULT=$2
	SCAN_NUM=$3 # How many ports we need to scan
	BASELINE_RESULT=$4
	sub=$5
	#echo -e "Scaanning ${BO}open ports${NC} for all public IPs in subscription: ${BL}${sub}${NC}"
	nmap -Pn -sS --top-ports ${SCAN_NUM} -oN "${SCAN_RESULT}" -iL "${HOSTS_TO_SCAN}" >/dev/null 2>&1
	#scan for UDP
	nmap -Pn -sU --top-ports ${SCAN_NUM} -oN "${SCAN_RESULT}" -iL "${HOSTS_TO_SCAN}" --append-output -d -v --reason --open >/dev/null 2>&1
	sed -i s'#\d\+\.\d\+s#<SomeNum>#g' "${SCAN_RESULT}"
	
	if [ ! -f "${BASELINE_RESULT}" ]; then
		echo -e "${RED}No baseline${NC} found for ${YEL}open ports${NC} scan result under subscription: ${LB}${sub}${NC}!"
		return
	fi
	tmp_dif="/tmp/${sub}-${today}-open-ports.$$"
	tmp_1="/tmp/baseline_openports.$$.nmap"
	tmp_2="/tmp/${today}_openports.$$.nmap"
	cat "${BASELINE_RESULT}" | grep -v 'Nmap.*\(initiated\|done\)' > ${tmp_1}
	cat "${SCAN_RESULT}" | grep -v 'Nmap.*\(initiated\|done\)' > ${tmp_2}
	diff -b "${tmp_1}" "${tmp_2}" > "${tmp_dif}"
	if [ -s "${tmp_dif}" ]; then
		echo
		echo "#########################################################################################"
		echo -e "Open ports ${BR}changed${NC} for subscription: ${LB}${sub}${NC}"
		echo "#########################################################################################"
		cat "${tmp_dif}"
		echo "#########################################################################################"
		echo "Diff Done"
		echo "#########################################################################################"
		echo
	fi
	rm -f "${tmp_dif}" "${tmp_1}" "${tmp_2}"
}

find "${IP_LIST_DIR}" -type f -maxdepth 3 -mtime -2 -name "${IP_LIST_FILE}" | grep "/${today}/" | while read f
do
	sub=${f#subs*/}
	sub=${sub%%/*}
	SCAN_RESULT="${IP_LIST_DIR}/${sub}/${today}/open_ports.nmap"
	BASELINE_RESULT="${IP_LIST_DIR}/${sub}/baseline/open_ports.nmap"
	HOSTS_TO_SCAN="${IP_LIST_DIR}/${sub}/${today}/hosts-to-scan.lst"
	echo -e "Scan ${YEL}open ports${NC} for all public IPs under subscription: ${BL}${sub}${NC}"
	cat "${f}" | jq '. | {ipAddress}' | grep 'ipAddress' | awk -F'"' '{print $4}' | grep -v '^$' > "${HOSTS_TO_SCAN}"
	scan_pub_ips "${HOSTS_TO_SCAN}" "${SCAN_RESULT}" "${SCAN_NUM}" "${BASELINE_RESULT}" "${sub}" &
done
