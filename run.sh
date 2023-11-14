#!/bin/bash
# Ban countries with firewalld and ipset script
# Created by Yevgeniy Goncharov, https://sys-adm.in

# Sys env / paths / etc
# -------------------------------------------------------------------------------------------\
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd); cd ${SCRIPT_PATH}

ZONES="br cn id mx py"
IPSET_NAME="blcountries"
IPDENY_ROOT_URL="https://www.ipdeny.com"
LOCAL_LIST="${SCRIPT_PATH}/local.list"
TMP_CATALOG="${SCRIPT_PATH}/tmp"
DOWNLOAD_CATALOG="${SCRIPT_PATH}/local-zones"
DOWNLOAD_FULL_CATALOG="${SCRIPT_PATH}/download"
UNPACK_CATALOG="${SCRIPT_PATH}/unpack"
MAX_SITE_TIMEOUT=5

# Usage
function usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    # echo "  -c, --countries <countries>  Countries to block (default: br cn in id)"
    echo "  -ln, --list-name <list>      Name of the ipset list (default: blcountries)"
    echo "  -mx, --maxelem <maxelem>     Maximum number of elements in the ipset list (default: 131072)"
    echo "  -hx, --hashsize <hashsize>   Hash size of the ipset list (default: 32768)"
    echo "  -am, --alternative-mirror    Another IP source mirror (default: ipdeny.com)"
    echo "  -daz, --download-all-zones   Download all country zones from ipdeny.com (all-zones.tar.gz)"
    echo "  -di, --delete-ipset          Delete ipset from firewalld (default: blcountries)"
    echo "  -dl, --download-local        Download zones to local folder"
    echo "  -sl, --setup-from-local      Setup ipsets from local downloaded zones"
    echo "  -sa, --setup-from-archive    Setup ipset from downloaded archive"
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
            ;;
        -ln|--list-name)
            LIST_NAME="$2"
            shift
            ;;
        -mx|--maxelem)
            MAXELEM="$2"
            shift
            ;;
        -hx|--hashsize)
            HASHSIZE="$2"
            shift
            ;;
        -am|--alternative-mirror)
            ANOTHER=1
            ;;
        -di|--delete-ipset)
            DELETE=1
            ;;
        -daz|--download-all-zones)
            DOWNLOAD_ALL_ZONES=1
            ;;
        -dl|--download-local)
            DOWNLOAD_LOCAL=1
            ;;
        -sl|--setup-from-local)
            SETUP_FROM_LOCAL=1
            ;;
        -sa|--setup-from-archive)
            SETUP_FROM_ARCHIVE=1
            ;;
        -ll|--local-country-list)
            LOCAL_COUNTRY_LIST=1
            ;;
        -d|--debug)
            DEBUG=1
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

# VAriables
if [[ -z ${COUNTRIES} ]]; then
    # COUNTRIES=${ZONES}
    if [[ ${LOCAL_COUNTRY_LIST} ]]; then
        COUNTRIES=$(cat ${LOCAL_LIST})
    else
        COUNTRIES=${ZONES}
    fi
fi

if [[ -z ${LIST_NAME} ]]; then
    LIST_NAME=${IPSET_NAME}
fi

if [[ -z ${MAXELEM} ]]; then
    MAXELEM=131072
fi

if [[ -z ${HASHSIZE} ]]; then
    HASHSIZE=4096
fi

# Actions
# ---------------------------------------------------\

# Check tmp exists
if [[ ! -d ${TMP_CATALOG} ]]; then
    mkdir -p ${TMP_CATALOG}
fi

# Check download exists
if [[ ! -d ${DOWNLOAD_CATALOG} ]]; then
    mkdir -p ${DOWNLOAD_CATALOG}
fi

# Check download exists
if [[ ! -d ${DOWNLOAD_FULL_CATALOG} ]]; then
    mkdir -p ${DOWNLOAD_FULL_CATALOG}
fi

# Check unpack exists
if [[ ! -d ${UNPACK_CATALOG} ]]; then
    mkdir -p ${UNPACK_CATALOG}
fi

function is_site_available() {

    if /usr/bin/curl -sSf --max-time "${MAX_SITE_TIMEOUT}" "${1}" --insecure 2>/dev/null >/dev/null; then
        true
    else
        false
    fi
}

function download_local() {

    if is_site_available "${IPDENY_ROOT_URL}"; then
        echo "Site ${IPDENY_ROOT_URL} is available. Ok"
    else
        echo "Site ${IPDENY_ROOT_URL} is not available. Exit..."
        exit 1
    fi

    for i in $COUNTRIES;do 
        echo "Downloading ${i}"
        curl -s ${IPDENY_ROOT_URL}/ipblocks/data/countries/${i}.zone --output ${DOWNLOAD_CATALOG}/${i}.zone
        echo "Files saved to ${DOWNLOAD_CATALOG}/${i}.zone"
    done

}

function check_all_zones_archive_size() {

    if is_site_available "${IPDENY_ROOT_URL}"; then
        echo "Site ${IPDENY_ROOT_URL} is available. Ok"
        echo "Checking file size..."
    else
        echo "Site ${IPDENY_ROOT_URL} is not available. Exit..."
        exit 1
    fi

    # Check file exists
    if [[ ! -f "${DOWNLOAD_FULL_CATALOG}/all-zones.tar.gz" ]]; then
        local LocalFileSize=$(stat -c%s "${DOWNLOAD_FULL_CATALOG}/all-zones.tar.gz")
        local RemoteFileSize=$(curl -sI ${IPDENY_ROOT_URL}/ipblocks/data/countries/all-zones.tar.gz | grep -i Content-Length | awk '{print $2}' | tr -d '\r')
        echo -e "Local file size: ${LocalFileSize}. Remote file size: ${RemoteFileSize}."

        if [[ "${LocalFileSize}" -eq "${RemoteFileSize}" ]]; then
            echo "File size is equal. Ok"
        else
            echo "File size is not equal. Downloading..."
            download_all_zones
        fi
    fi

}

function download_all_zones(){
    
    if is_site_available "${IPDENY_ROOT_URL}"; then
        echo "Site ${IPDENY_ROOT_URL} is available. Ok"
    else
        echo "Site ${IPDENY_ROOT_URL} is not available. Exit..."
        exit 1
    fi

    curl -s ${IPDENY_ROOT_URL}/ipblocks/data/countries/all-zones.tar.gz --output ${DOWNLOAD_FULL_CATALOG}/all-zones.tar.gz
    echo "File saved to ${DOWNLOAD_FULL_CATALOG}/all-zones.tar.gz"
    tar -xzf ${DOWNLOAD_FULL_CATALOG}/all-zones.tar.gz -C ${UNPACK_CATALOG}
    echo "Files unpacked to ${UNPACK_CATALOG}"

}

function check_all_zones_archive_size() {

    if is_site_available "${IPDENY_ROOT_URL}"; then
        echo "Site ${IPDENY_ROOT_URL} is available. Ok"
        echo "Checking file size..."
    else
        echo "Site ${IPDENY_ROOT_URL} is not available. Exit..."
        exit 1
    fi

    # Check file exists
    if [[ ! -f "${DOWNLOAD_FULL_CATALOG}/all-zones.tar.gz" ]]; then
        echo "File not exists. Downloading..."
        download_all_zones
    fi

    local LocalFileSize=$(wc -c < "${DOWNLOAD_FULL_CATALOG}/all-zones.tar.gz" | tr -d ' ')
    local RemoteFileSize=$(curl -sI ${IPDENY_ROOT_URL}/ipblocks/data/countries/all-zones.tar.gz | awk '/content-length/ {sub("\r",""); print $2}' | tr -d ' ')
    echo -e "Local file size: ${LocalFileSize}. Remote file size: ${RemoteFileSize}."

    if [[ "${LocalFileSize}" -eq "${RemoteFileSize}" ]]; then
        echo "File size is equal. Ok"
    else
        echo "File size is not equal. Downloading..."
        download_all_zones
    fi

}

function setup_from_archive(){
    
    # Check file exists
    if [[ ! -f "${DOWNLOAD_FULL_CATALOG}/all-zones.tar.gz" ]]; then
        echo "File not exists. Downloading..."
        download_all_zones
    else
        tar -xzf ${DOWNLOAD_FULL_CATALOG}/all-zones.tar.gz -C ${UNPACK_CATALOG}
        echo "Files unpacked to ${UNPACK_CATALOG}"
    fi

    for i in $COUNTRIES;do 
        echo "Checking ${UNPACK_CATALOG}/${i}.zone"

        if [[ -f "${UNPACK_CATALOG}/${i}.zone" ]]; then
            echo "Processing ${i}"
            firewall-cmd --permanent --ipset=${LIST_NAME} --add-entries-from-file=${UNPACK_CATALOG}/${i}.zone
        else
            echo "File ${i}.zone not found. Exit..."
        fi
    done

}

function delete_ipset() {

    if (systemctl -q is-active firewalld.service)
    then
        if firewall-cmd --permanent --get-ipsets | grep -q "${LIST_NAME}"; then
            echo -e "\nDeleting ${LIST_NAME} with standard method..."
            firewall-cmd --permanent --zone=drop --remove-source=ipset:"${LIST_NAME}" &> /dev/null
            firewall-cmd --reload &> /dev/null
            firewall-cmd --permanent --delete-ipset=${LIST_NAME} &> /dev/null
            # grep -rl "${LIST_NAME}" /etc/firewalld | xargs sed -i "/${LIST_NAME}/d"
            firewall-cmd --reload
        fi
    else
        rm  /etc/firewalld/ipsets/${LIST_NAME}.xml
        grep -rl "${LIST_NAME}" /etc/firewalld | xargs sed -i "/${LIST_NAME}/d"
        systemctl restart firewalld
    fi

}

# Add existing ipset to drop zone
function check_drop() {
    if firewall-cmd --permanent --get-ipsets | grep -q "${LIST_NAME}"; then
        echo "Drops ${LIST_NAME} is exists. Ok"
    else
        echo "Add list ${LIST_NAME} to drop zone."
        firewall-cmd --permanent --zone=drop --add-source=ipset:${LIST_NAME}
        firewall-cmd --reload
    fi
}

function create_ipset() {    
    
    echo -e "\nCreating new list ${LIST_NAME}..."
    # firewall-cmd --permanent --new-ipset=${LIST_NAME} --type=hash:net --option=maxelem=${MAXELEM}
    firewall-cmd --permanent --new-ipset=${LIST_NAME} --type=hash:net --option=family=inet --option=hashsize=${HASHSIZE} --option=maxelem=${MAXELEM} > /dev/null 2> /dev/null
    if [[ $? -eq 0 ]];then
        firewall-cmd --reload
    else
        echo -e "Couldn't create the blacklist ${LIST_NAME}. Exit..."
        exit 1
    fi

}

function setup_from_online() {
    if [[ "$ANOTHER" -eq "1" ]]; then
        echo "Mirror mode - Ludost.net"
        curl -s -d country=1 --data-urlencode "country_list=br cn in id" -d format_template=prefix https://ip.ludost.net/cgi/process | grep -v "^#" > ${TMP_CATALOG}/ludost.zone
        firewall-cmd --permanent --ipset=${LIST_NAME} --add-entries-from-file=${TMP_CATALOG}/ludost.zone
    else
        for i in $COUNTRIES;do 
            echo "Processing ${i}"
            curl -s ${IPDENY_ROOT_URL}/ipblocks/data/countries/${i}.zone --output ${TMP_CATALOG}/${i}.zone
            echo "File saved to ${TMP_CATALOG}/${i}.zone. Adding to ipset ${LIST_NAME}..."
            firewall-cmd --permanent --ipset=${LIST_NAME} --add-entries-from-file=${TMP_CATALOG}/${i}.zone > /dev/null 2> /dev/null
            if [[ $? -eq 0 ]];then
                echo -e "Zone ${i} successfully added to ${LIST_NAME}"
            else
                echo -e "Couldn't add zone ${i} to ${LIST_NAME}. Exit..."
                exit 1
            fi
        done
    fi
    
}

function setup_from_local() {
    # list files in download catalog
    echo ""

    if is_site_available "${IPDENY_ROOT_URL}"; then
        echo "Updating local zones..."
        download_local
    fi

    for c in $COUNTRIES;do 
        if [[ ! -f "${DOWNLOAD_CATALOG}/${c}.zone" ]]; then
            echo "File ${DOWNLOAD_CATALOG}/${c}.zone not found!"
        else
            echo "File ${DOWNLOAD_CATALOG}/${c}.zone found. Adding to ipset ${LIST_NAME}..."
            firewall-cmd --permanent --ipset=${LIST_NAME} --add-entries-from-file=${DOWNLOAD_CATALOG}/${c}.zone > /dev/null 2> /dev/null
        fi

    done

    # for i in $(ls ${DOWNLOAD_CATALOG}); do
    #     echo "Processing ${DOWNLOAD_CATALOG}/${i}"
    #     firewall-cmd --permanent --ipset=${LIST_NAME} --add-entries-from-file=${DOWNLOAD_CATALOG}/${i}
    # done
}

function checking_firewalld_status(){
    if (systemctl -q is-active firewalld.service)
    then
        echo -e "\nFirewalld is active. Ok"
        echo -e "Done!\n"
    else
        echo "Firewalld is not active. Exit..."
        exit 1
    fi
}

function add_ipset_to_drop_zone(){
    echo -e "\nAdding ipset ${LIST_NAME} to drop zone..."
    firewall-cmd --permanent --zone=drop --add-source="ipset:${LIST_NAME}"
}

# Main

if [[ "$DOWNLOAD_ALL_ZONES" -eq "1" ]]; then
    check_all_zones_archive_size
    exit 0
fi


if [[ "$DOWNLOAD_LOCAL" -eq "1" ]]; then
    download_local
    exit 0
fi

if [[ "$DELETE" -eq "1" ]]; then
    delete_ipset
    exit 0
fi

# If DEBUG skip this steps
if [[ ! "$DEBUG" -eq "1" ]]; then
    delete_ipset
    create_ipset
fi

if [[ "$SETUP_FROM_LOCAL" -eq "1" ]]; then
    echo $COUNTRIES
    setup_from_local
elif [[ "$SETUP_FROM_ARCHIVE" -eq "1" ]]; then
    setup_from_archive
else
    setup_from_online
fi


if [[ ! "$DEBUG" -eq "1" ]]; then
    # check_drop
    add_ipset_to_drop_zone
    sleep 5
    firewall-cmd --reload
    checking_firewalld_status
fi


# firewall-cmd --permanent --ipset=blcountries --get-entries
# curl https://www.ipdeny.com/ipblocks/data/countries/${i}.zone --output /tmp/${i}.zone
# firewall-cmd --permanent --delete-ipset=blcountries; firewall-cmd --reload
# curl -s -d country=1 --data-urlencode "country_list=br cn in id" -d format_template=prefix https://ip.ludost.net/cgi/process
