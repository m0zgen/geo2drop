#!/bin/bash
# Ban countries with firewalld and ipset script
# Created by Yevgeniy Goncharov, https://sys-adm.in

# Sys env / paths / etc
# -------------------------------------------------------------------------------------------\
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)

# Initial variables
# ---------------------------------------------------\
COUNTRIES=(br cn in)
LIST_NAME="block-countries"
MAXELEM=131072
HASHSIZE=32768
TMP_CATALOG="${SCRIPT_PATH}/tmp"

# Actions
# ---------------------------------------------------\

# Check tmp exists
if [[ ! -d ${TMP_CATALOG} ]]; then
    mkdir -p ${TMP_CATALOG}
fi

function check_drop() {
    firewall-cmd --list-all --zone=drop > ${TMP_CATALOG}/drops.txt
    if [[ $(grep -c "${LIST_NAME}" ${TMP_CATALOG}/drops.txt) -eq 1 ]]; then
        echo "Drops ${LIST_NAME} is exists. Ok"
    else
        echo "Add list ${LIST_NAME} to drop zone."
        firewall-cmd --permanent --zone=drop --add-source=ipset:${LIST_NAME}
        firewall-cmd --reload
    fi
}

function get_sets() {
    firewall-cmd --permanent --get-ipsets > ${TMP_CATALOG}/ipsets.txt
    if [[ $(grep -c "${LIST_NAME}" ${TMP_CATALOG}/ipsets.txt) -eq 1 ]]; then
        echo "List ${LIST_NAME} is exists. Ok"
    else
        echo "Add new list ${LIST_NAME}"
        # firewall-cmd --permanent --new-ipset=${LIST_NAME} --type=hash:net --option=maxelem=${MAXELEM}
        firewall-cmd --permanent --new-ipset=${LIST_NAME} --type=hash:net --option=hashsize=${HASHSIZE} --option=maxelem=${MAXELEM}
        firewall-cmd --permanent --zone=drop --add-source=ipset:${LIST_NAME}
        firewall-cmd --reload
    fi
}

function push_list() {
    for i in "${COUNTRIES[@]}"; do
        echo "Processing ${i}"
        curl -s https://www.ipdeny.com/ipblocks/data/countries/${i}.zone --output ${TMP_CATALOG}/${i}.zone
        firewall-cmd --permanent --ipset=${LIST_NAME} --add-entries-from-file=${TMP_CATALOG}/${i}.zone
    done
}

get_sets
check_drop
push_list
firewall-cmd --reload
echo "Done!"

# firewall-cmd --permanent --ipset=block-countries --get-entries
# curl https://www.ipdeny.com/ipblocks/data/countries/${i}.zone --output /tmp/${i}.zone
# firewall-cmd --permanent --delete-ipset=blockcountries; firewall-cmd --reload
