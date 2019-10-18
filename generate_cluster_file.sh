#!/bin/bash

if [ "$#" -ne 1 ]
then
  echo "Usage: generate_cluster_file.sh <output file name>"
  exit 1
fi

   
NODES=$(echo ${NODES} | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
OUT_FILE=$1

NODES_ARR=()
while read -r line; do
     NODES_ARR+=("$line")
done <<< "${NODES}"

echo " " > ${OUT_FILE}
echo "[master-nodes]" >>  ${OUT_FILE}
echo "master01 ansible_host=${NODES_ARR[0]} " >>  ${OUT_FILE}

echo " " >> ${OUT_FILE}
echo "[slave-nodes]" >>  ${OUT_FILE}

count=1
while [ "x${NODES_ARR[$count]}" != "x" ]
do
  echo "slave0${count} ansible_host=${NODES_ARR[$count]} " >>  ${OUT_FILE}
  count=$(( $count + 1 ))
done

REST=$(cat <<-END_OF_REST
[all-nodes:children]
master-nodes
slave-nodes

[all-nodes:vars]
ansible_user=root
ansible_ssh_private_key_file=/root/gautam/keys/${HW_KEYPAIR}
END_OF_REST
)

echo "$REST" >> ${OUT_FILE}

cat playbooks/group_vars/all.tmpl | envsubst > playbooks/group_vars/all


