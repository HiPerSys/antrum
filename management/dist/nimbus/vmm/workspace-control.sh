#!/bin/bash

# Modified by: Joshua McKee

PYTHON_EXE="/usr/bin/env python"

NIMBUS_CONTROL_DIR_REL="`dirname $0`/.."
NIMBUS_CONTROL_DIR=`cd $NIMBUS_CONTROL_DIR_REL; pwd`

NIMBUS_CONTROL_MAINCONF="$NIMBUS_CONTROL_DIR/etc/workspace-control/main.conf"

if [ ! -f "$NIMBUS_CONTROL_MAINCONF" ]; then
    echo ""
    echo "Cannot find main conf file, exiting. (expected at '$NIMBUS_CONTROL_MAINCONF')"
    exit 1
fi

NIMBUS_CONTROL_PYLIB="$NIMBUS_CONTROL_DIR/lib/python"
NIMBUS_CONTROL_PYSRC="$NIMBUS_CONTROL_DIR/src/python"
PYTHONPATH="$NIMBUS_CONTROL_PYSRC:$NIMBUS_CONTROL_PYLIB:$PYTHONPATH"
export PYTHONPATH

# -----------------------------------------------------------------------------

##########################
### BEGIN MODIFICATION ###
##########################
#
# DESCRIPTION:
# Aquires a few values from the available paramters, and runs the vm network 
# setup/cleanup scripts as appropriate.

# the location of the vm network setup/cleanup scripts
SCRIPTS_DIR="/usr/local/bin"

action=`echo $@ | tr ' ' '\n' | sed -n '/--action/{n;p}'`
if [ -z "$action" ]; then
    action=`echo $@ | awk '{print $1}' | sed 's/--//'`
fi
vm_name=`echo $@ | tr ' ' '\n' | sed -n '/--name/{n;p}'`

if [[ $action == create ]]; then
    vm_ips=`echo $@ | tr ' ' '\n' | sed -n '/--network/{n;p}' | tr ';' '\n' | sed -n '6~16p' | egrep '[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}'`
    i=0
    for vm_ip in $vm_ips; do
	$SCRIPTS_DIR/setup-vm-network $vm_name-$i $vm_ip
	let i++
    done
fi

##########################
### PAUSE MODIFICATION ###
##########################

$PYTHON_EXE $NIMBUS_CONTROL_PYSRC/workspacecontrol/main/wc_cmdline.py -c $NIMBUS_CONTROL_MAINCONF "$@"

##########################
### CONT' MODIFICATION ###
##########################

if [[ $action == remove ]]; then
    nics=`/sbin/ifconfig -a | grep -w "$vm_name" | awk '{print $1}'`
    for nic in $nics; do
	$SCRIPTS_DIR/cleanup-vm-network $nic
    done
fi

##########################
###  END MODIFICATION  ###
##########################
