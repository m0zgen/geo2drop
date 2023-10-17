#!/bin/bash
# Ban countries with firewalld and ipset script
# Created by Yevgeniy Goncharov, https://sys-adm.in

# Sys env / paths / etc
# -------------------------------------------------------------------------------------------\
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)

# Usage
function usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -c, --countries <countries>  Countries to block (default: br cn in id)"
    echo "  -l, --list <list>            Name of the ipset list (default: blcountries)"
    echo "  -mx, --maxelem <maxelem>     Maximum number of elements in the ipset list (default: 131072)"
    echo "  -hx, --hashsize <hashsize>   Hash size of the ipset list (default: 32768)"
    echo "  -a, --another                Another IP source mirror (default: ipdeny.com)"
    echo "  -d, --delete                 Delete ipset from firewalld (default: blcountries)"
    echo "  -h, --help                   Show this message (help)"
    exit 0
}

# Arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -c|--countries)
            COUNTRIES="$2"
            shift
            shift
            ;;
        -l|--list)
            LIST_NAME="$2"
            shift
            shift
            ;;
        -mx|--maxelem)
            MAXELEM="$2"
            shift
            shift
            ;;
        -hx|--hashsize)
            HASHSIZE="$2"
            shift
            shift
            ;;
        -a|--another)
            ANOTHER=1
            shift
            shift
            ;;
        -d|--delete)
            DELETE=1
            shift
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# VAriables
if [[ -z ${COUNTRIES} ]]; then
    COUNTRIES="br cn in id"
fi

if [[ -z ${LIST_NAME} ]]; then
    LIST_NAME="blcountries"
fi

if [[ -z ${MAXELEM} ]]; then
    MAXELEM=131072
fi

if [[ -z ${HASHSIZE} ]]; then
    HASHSIZE=32768
fi

TMP_CATALOG="${SCRIPT_PATH}/tmp"

# Actions
# ---------------------------------------------------\

# Check tmp exists
if [[ ! -d ${TMP_CATALOG} ]]; then
    mkdir -p ${TMP_CATALOG}
fi

function delete() {

    if (systemctl -q is-active firewalld.service)
    then
        echo "Delete ${LIST_NAME} from firewalld with standard method"
        firewall-cmd --permanent --delete-ipset=${LIST_NAME}
        grep -rl '${LIST_NAME}' /etc/firewalld | xargs sed -i '/${LIST_NAME/d'
        firewall-cmd --reload
        echo "Ipset ${LIST_NAME} deleted"
        exit 1
    else
        rm  /etc/firewalld/ipsets/${LIST_NAME}.xml
        grep -rl '${LIST_NAME}' /etc/firewalld | xargs sed -i '/${LIST_NAME/d'
        systemctl restart firewalld
    fi

}

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
    if [[ "$ANOTHER" -eq "1" ]]; then
        echo "Mirror mode - Ludost.net"
        curl -s -d country=1 --data-urlencode "country_list=br cn in id" -d format_template=prefix https://ip.ludost.net/cgi/process | grep -v "^#" > ${TMP_CATALOG}/ludost.zone
        firewall-cmd --permanent --ipset=${LIST_NAME} --add-entries-from-file=${TMP_CATALOG}/ludost.zone
    else
        for i in $COUNTRIES;do 
            echo "Processing ${i}"
            curl -s https://www.ipdeny.com/ipblocks/data/countries/${i}.zone --output ${TMP_CATALOG}/${i}.zone
            firewall-cmd --permanent --ipset=${LIST_NAME} --add-entries-from-file=${TMP_CATALOG}/${i}.zone
        done
    fi
    
}

if [[ "$DELETE" -eq "1" ]]; then
    delete
    exit 0
fi

get_sets
check_drop
push_list
firewall-cmd --reload
echo "Done!"

# firewall-cmd --permanent --ipset=blcountries --get-entries
# curl https://www.ipdeny.com/ipblocks/data/countries/${i}.zone --output /tmp/${i}.zone
# firewall-cmd --permanent --delete-ipset=blcountries; firewall-cmd --reload
# curl -s -d country=1 --data-urlencode "country_list=br cn in id" -d format_template=prefix https://ip.ludost.net/cgi/process
