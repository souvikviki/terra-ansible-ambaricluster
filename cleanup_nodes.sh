#!/bin/bash

DEBUG="-v" #Default

while [[ $# > 0 ]]
do
	key="$1"
	case $key in
	    --debug)
	    DEBUG="-vvv"
	    shift # skip argument
	    ;;
	    --default)
	    DEFAULT=YES
	    ;;
	    *)
	            # unknown option
	    ;;
	esac
	shift # past argument or value
done

VARS="${VARS} ANSIBLE_SCP_IF_SSH=y ANSIBLE_HOST_KEY_CHECKING=False"

export $VARS
ansible-playbook $DEBUG -f 20 -i inventory/cluster playbooks/cleanup.yml
