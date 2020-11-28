#!/bin/sh

# Azure CLI documentation: https://docs.microsoft.com/en-us/cli/azure/

RED='\033[0;31m'
BR='\033[1;31m' # Bold Red
NC='\033[0m' # No color
BO='\033[0;33m' # Brown/Orange
YEL='\033[1;33m' # Yellow
BL='\033[0;34m'  # Blue
LB='\033[1;34m'  # Light Blue
RESULT_FOLDER="subs"
TMP_FILE=/tmp/azurecli.tmp.$$
SUBLIST=/tmp/azure_sub_list.tmp.$$
today=`date '+%F'`

mkdir -p "${RESULT_FOLDER}"
az account list | jq --sort-keys '.[] | {name}' | grep '^[ ]*"name":' | awk -F'"' '{print $4}' > ${SUBLIST}


function prepare_folders() {
	cat ${SUBLIST} | while read sub
	do
		SUBSCRIPT_FOLDER="${RESULT_FOLDER}/${sub}/${today}"
		mkdir -p "${SUBSCRIPT_FOLDER}"
	done
}

function comp_with_baseline() {
	sub="$1"
	category="$2"
	baseline="${RESULT_FOLDER}/${sub}/baseline/${category}"
	curr="${RESULT_FOLDER}/${sub}/${today}/${category}"
	if [ ! -f "${baseline}" ]; then
		echo -e "${RED}No baseline${NC} defined for ${BO}${category}${NC} under subscription: ${LB}${sub}${NC}!"
		return
	fi
	tmp_dif="/tmp/${sub}-${today}-${category}.$$"
	diff -b "${baseline}" "${curr}" > "${tmp_dif}"
	if [ -s "${tmp_dif}" ]; then
		echo
		echo "#########################################################################################"
		echo -e "Config ${BR}changed${NC} for ${BO}${category}${NC} in subscription: ${LB}${sub}${NC}"
		echo "#########################################################################################"
		cat "${tmp_dif}"
		echo "#########################################################################################"
		echo "Diff Done"
		echo "#########################################################################################"
		echo
	fi
	rm -f "${tmp_dif}"
}

function check_net_usage() {
	category="Network Usage"
	cat ${SUBLIST} | while read sub
	do
		SUBSCRIPT_FOLDER="${RESULT_FOLDER}/${sub}/${today}"
		az network list-usages --location chinanorth2 -o table --subscription "${sub}" > "${SUBSCRIPT_FOLDER}/${category}"
		comp_with_baseline "${sub}" "${category}"
	done
}

function check_nsg() {
	category="Network Security Group"
	cat ${SUBLIST} | while read sub
	do
		SUBSCRIPT_FOLDER="${RESULT_FOLDER}/${sub}/${today}"
		az network nsg list --subscription "${sub}" | jq --sort-keys . | egrep -v '^[ \t]*"etag":' > "${SUBSCRIPT_FOLDER}/${category}"
		comp_with_baseline "${sub}" "${category}"
	done
}

function check_pub_ip() {
	category="Public IP Addresses"
	cat ${SUBLIST} | while read sub
	do
		SUBSCRIPT_FOLDER="${RESULT_FOLDER}/${sub}/${today}"
		az network public-ip list --subscription "${sub}" | jq '.[] | {name, ipAddress, resourceGroup, location, type, provisioningState}' > "${SUBSCRIPT_FOLDER}/${category}"
		comp_with_baseline "${sub}" "${category}"
	done
}

prepare_folders

check_net_usage

check_nsg

check_pub_ip

rm -f ${TMP_FILE} ${SUBLIST}
