#!/bin/bash

####################################################################################################################
#### Tested with the following:
####    - GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin19)
####    - GNU bash, version 5.1.4(1)-release (x86_64-apple-darwin19.6.0)
####    - zsh 5.8 (x86_64-apple-darwin19.6.0)
####################################################################################################################

####################################################################################################################
#### IMPORTANT NOTE
#### VAULT_ADDR WILL ONLY WORK IF IT DOESN'T ENDS WITH A "/"
#### e.g: export VAULT_ADDR="https://127.0.0.1:8200"
#### If you want to keep your current VAULT_ADDR value, please replace the following lines with the content below:
#### every line including: ${VAULT_ADDR}/
#### should be replaced by ${VAULT_ADDR} if you already are using a "/" at the of VAULT_ADDR
####
#### If you're using a certificate not trusted by Vault, for you request, you should at least have VAULT_CACERT set
#### in your environment, pointing to the appropriate file.
####################################################################################################################
function verifies_data_time () {
    
    creation_date=( `curl -s --header "X-Vault-Token: ${VAULT_TOKEN}" --header "X-Vault-Namespace: ${1}"  -X GET  "${VAULT_ADDR}/v1/identity/entity/id/${2}" | jq .data.creation_time | sed 's/[],[]//g'` )
    python3 verif_date.py $creation_date $min_date $max_date
    New=$?
}

is_active_during_period () {
    is_active=0
    for active_entity in "${active_entity_arr[@]}"
    do 
        if [ "$active_entity" == "$1" ]; then
            is_active=1
        fi
    done
}

function write_data_to_output_file () {
    #curl -s --header "X-Vault-Token: ${VAULT_TOKEN}" --header "X-Vault-Namespace: ${1}"  -X GET  "${VAULT_ADDR}/v1/identity/entity/id/${2}" | jq .data | sed 's/[],[]//g'  >> $output_file
    my_data=( `curl -s --header "X-Vault-Token: ${VAULT_TOKEN}" --header "X-Vault-Namespace: ${1}"  -X GET  "${VAULT_ADDR}/v1/identity/entity/id/${2}" | jq -c .data ` )
    echo $my_data
    my_id=( `echo $my_data | jq -r '.id' ` )
    my_name=( `echo $my_data | jq -r '.name' ` )
    my_creation_time=( `echo $my_data | jq -r '.creation_time' ` )
    my_namespace_id=( `echo $my_data | jq -r '.namespace_id' ` )
    my_namespace_name=${1}
    my_mount_accessor=( `echo $my_data | jq -r '.aliases[] | .mount_accessor' ` )
    my_mount_path=( `echo $my_data | jq -r '.aliases[] | .mount_path' ` )
    my_mount_name=( `echo $my_data | jq -r '.aliases[] | .name' ` )
    is_active_during_period $my_id
    echo $my_id ";" $my_name ";" $my_creation_time ";" $my_namespace_id ";" $my_namespace_name ";" $my_mount_accessor ";" $my_mount_path ";" $my_mount_name ";" $is_active >> $output_file
}


function return_entites {
        #echo 'X-Vault-Namespace in return_entites:' ${1}
        entities_arr=( `curl -s --header "X-Vault-Token: ${VAULT_TOKEN}" --header "X-Vault-Namespace: ${1}"  -X LIST "${VAULT_ADDR}/v1/identity/entity/id" | jq -r '.data.keys' | sed 's/[],[]//g'` )
        for entities in "${entities_arr[@]}"
        do
            if [[ "$entities" != "null" ]]; then 
                echo 'entities' ${entities//\"} 
                verifies_data_time "${1}" "${entities//\"}"
                if [[ "$New" = "1" ]]; then
                    NEW_ENTITIES=${entities}
                    write_data_to_output_file "${1}" "${entities//\"}"
                fi   
            else
                    echo 'X-Vault-Namespace in return_entites:' ${1}
                    echo 'empty entities'
            fi
        done
} 

function go_one_ns_deeper() {
for ns in "$1"
do
    namespaces_arr=( `curl -s --header "X-Vault-Token: ${VAULT_TOKEN}" --header "X-Vault-Namespace: ${2}" -X LIST "${VAULT_ADDR}/v1/sys/namespaces/" | jq -r '.data.keys' | sed 's/[],[]//g'` )
    if [[ "$namespaces_arr" != "null" ]]; then
        return_entites "$2"
        for sub_namespace in "${namespaces_arr[@]}" 
        do  
            echo 'X-Vault-Namespace 2:' "$2${sub_namespace//\"}"
            return_entites "$2${sub_namespace//\"}"
            go_one_ns_deeper "${sub_namespace//\"}" "$2${sub_namespace//\"}"
        done
    fi
done
}

if [ -z "$VAULT_TOKEN" ]
then
    echo "\$VAULT_TOKEN must be set." >&2
	exit -1
fi

if [ -z "$VAULT_ADDR" ]
then
    echo "\$VAULT_ADDR must be set." >&2
	exit -1
fi

if [ -z jq ]
then
    echo "jq must be installed" >&2
	exit -1
fi

if [ -z sed ]
then
    echo "sed must be installed" >&2
	exit -1
fi

output_file=/tmp/output.csv
echo "id" ";" "name" ";" "creation_time" ";" "namespace_id" ";" "namespace_name" ";" "accessor" ";" "mount_path" ";" "mount_name" ";" "is_active_during_period" > $output_file
min_date2=$1'T00:00:00Z'
max_date2=$2'T23:59:59Z'
min_date=$1
max_date=$2
active_entity_arr=( `curl -s --header "X-Vault-Token: ${VAULT_TOKEN}" -X GET  "${VAULT_ADDR}/v1/sys/internal/counters/activity/export?start_time=${min_date2}&end_time=${max_date2}" | jq .client_id | sed 's/[],[]//g' | sed 's/\"//g'` )

return_entites 'root'
root_namespace_arr=( `curl -s --header "X-Vault-Token: ${VAULT_TOKEN}"  -X LIST "${VAULT_ADDR}/v1/sys/namespaces/" | jq .data.keys | sed 's/[],[]//g'` ) # Get the namespace list under / in a sanitised bash array


for ns in "${root_namespace_arr[@]}"
do
    go_one_ns_deeper "${ns//\"}" "${ns//\"}"
done
