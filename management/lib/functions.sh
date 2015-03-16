### PYTHON FUNCTIONS ###

# calls a python function $1 with params $2,...,$n (passed as strings)
_call_python_function()
{
    local params=${@:2}
    python -c "import imp; functions = imp.load_source(\"functions\", \"$TB_PYTHON_FUNCTIONS_LIB_FILE\"); print functions.$1($(echo \'${params// /\', \'}\'));" | sed '${/None/d;}'
}

# checks if $1 is in the network $2
in_network()
{
    [[ $(_call_python_function inNetwork $1 $2) == "True" ]]
}

# checks if $1 is a valid ip address
is_valid_ip()
{
    [[ $(_call_python_function isValidIP $1) == "True" ]]
}

# returns a list of ip addresses in the network (separated by a newline)
get_ips_in_network()
{
    _call_python_function getIPsInNetwork $1
}

# returns the number of ip addresses in the network
get_no_ips_in_network()
{
    _call_python_function getNoIPsInNetwork $1
}

### TESTBED HOSTS LIST FUNTIONS ###

# adds new host $1 to the testbed hosts list (no values set)
add_testbed_host()
{
    echo -e "$1\tNONE\tNONE\tNONE\tNONE" >> $TB_HOSTS_FILE
}

# removes host $1 from the testbed hosts list
remove_testbed_host()
{
    sed -i "/^$1\t.*$/d" $TB_HOSTS_FILE
}

# checks if $1 belongs to the testbed
is_testbed_host()
{
    [ -n $1 ] || return 1

    if is_valid_ip $1; then
	grep -Fqw "$1" $TB_HOSTS_FILE
    else
	cut -f1 $TB_HOSTS_FILE | grep -Fqw "$1"
    fi
}

# returns all testbed host names
get_testbed_hosts()
{
    for host in $(cut -f1 $TB_HOSTS_FILE); do
	echo $host
    done
}

# returns all testbed host names with olsr IP addresses
get_olsr_testbed_hosts()
{
    for host in $(cut -f1 $TB_HOSTS_FILE); do
	if tb_host_has_olsr_ip $host; then
	    echo $host
	fi    
    done
}

# returns the host name of the testbed head node
get_testbed_head_node()
{
    for host in $(cut -f1 $TB_HOSTS_FILE); do
	if tb_host_is_head_node $host; then
	    echo $host
	    return 0
	fi    
    done
}

# returns all the host names of the testbed vmm nodes
get_testbed_vmm_nodes()
{
    for host in $(cut -f1 $TB_HOSTS_FILE); do
	if tb_host_is_vmm_node $host; then
	    echo $host
	fi    
    done
}

# returns the host name running the phantom vm
get_testbed_phantom_vm_node()
{
    for host in $(cut -f1 $TB_HOSTS_FILE); do
	if tb_host_is_phantom_vm_node $host; then
	    echo $host
	    return 0
	fi    
    done
}

# returns all the host names of the testbed client nodes
get_testbed_client_nodes()
{
    for host in $(cut -f1 $TB_HOSTS_FILE); do
	if tb_host_is_client_node $host; then
	    echo $host
	fi    
    done
}

# gets the host name of host $1
get_tb_host_name()
{
    echo `awk '/'$1'/{ print $1 }' $TB_HOSTS_FILE`
}

# sets the wired IP address of host $1 to $2
set_tb_host_wired_ip()
{
    sed -i "/$1/s/[^\t]*[^\t]/$2/2" $TB_HOSTS_FILE
}

# gets the wired IP address of host $1
get_tb_host_wired_ip()
{
    echo `awk '/'$1'/{ print $2 }' $TB_HOSTS_FILE`
}

# sets the olsr IP address of host $1 to $2
set_tb_host_olsr_ip()
{
    sed -i "/$1/s/[^\t]*[^\t]/$2/3" $TB_HOSTS_FILE
}

# gets the olsr IP address of host $1
get_tb_host_olsr_ip()
{
    echo `awk '/'$1'/{ print $3 }' $TB_HOSTS_FILE`
}

# checks if host $1 has an olsr ip address
tb_host_has_olsr_ip()
{
    [[ $(awk '/'$1'/{ print $3 }' $TB_HOSTS_FILE) != "NONE" ]]
}

# sets the wireless interface name of host $1 to $2
set_tb_host_wifi_iface()
{
    sed -i "/$1/s/[^\t]*[^\t]/$2/4" $TB_HOSTS_FILE
}

# gets the wireless interface name of host $1
get_tb_host_wifi_iface()
{
    echo `awk '/'$1'/{ print $4 }' $TB_HOSTS_FILE`
}

# sets the nimbus node type of host $1 to $2
_set_tb_host_node_type()
{
    if [[ $(_get_tb_host_node_types $1) == "NONE" ]]; then
	sed -i "/$1/s/[^\t]*[^\t]/$2/5" $TB_HOSTS_FILE
    else
	sed -i "/$1/s/[^\t]*[^\t]/&,$2/5" $TB_HOSTS_FILE
    fi
}

# unsets the nimbus node type $2 of host $1
_unset_tb_host_node_type()
{
    if [[ $(_get_tb_host_node_types $1) == *,* ]]; then
	tmp_host_node_types=$(echo `_get_tb_host_node_types $1` | \
	    sed -e "s/$2,\?//" -e "s/^,//" -e "s/,$//")
	sed -i "/$1/s/[^\t]*[^\t]/$tmp_host_node_types/5" $TB_HOSTS_FILE
    else
	sed -i "/$1/s/[^\t]*[^\t]/NONE/5" $TB_HOSTS_FILE
    fi
}

# gets the nimbus node types of host $1
_get_tb_host_node_types()
{
    echo `awk '/'$1'/{ print $5 }' $TB_HOSTS_FILE`
}

# checks if host $1 is the head node
tb_host_is_head_node()
{
    [[ $(_get_tb_host_node_types $1) == *HEAD* ]]
}

# sets host $1 as the head node
set_tb_host_as_head_node()
{
    _set_tb_host_node_type $1 "HEAD"
}

# unsets host $1 as the head node
unset_tb_host_as_head_node()
{
    _unset_tb_host_node_type $1 "HEAD"
}

# checks if head node exists
tb_host_head_node_exists()
{
    cut -f5 $TB_HOSTS_FILE | grep -Fqw "HEAD"
}

# checks if host $1 is a client node
tb_host_is_client_node()
{
    [[ $(_get_tb_host_node_types $1) == *CLIENT* ]]
}

# sets host $1 as a client node
set_tb_host_as_client_node()
{
    _set_tb_host_node_type $1 "CLIENT"
}

# unsets host $1 as a client node
unset_tb_host_as_client_node()
{
    _unset_tb_host_node_type $1 "CLIENT"
}

# checks if at least one client node exists
tb_host_client_node_exists()
{
    cut -f5 $TB_HOSTS_FILE | grep -Fqw "CLIENT"
}

# checks if host $1 is a vmm node
tb_host_is_vmm_node()
{
    [[ $(_get_tb_host_node_types $1) == *VMM* ]]
}

# sets host $1 as a vmm node
set_tb_host_as_vmm_node()
{
    _set_tb_host_node_type $1 "VMM"
}

# unsets host $1 as a vmm node
unset_tb_host_as_vmm_node()
{
    _unset_tb_host_node_type $1 "VMM"
}

# checks if at least one vmm node exists
tb_host_vmm_node_exists()
{
    cut -f5 $TB_HOSTS_FILE | grep -Fqw "VMM"
}

# checks if host $1 is running the phantom vm
tb_host_is_phantom_vm_node()
{
    [[ $(_get_tb_host_node_types $1) == *PHAN* ]]
}

# sets host $1 as running the phantom vm
set_tb_host_as_phantom_vm_node()
{
    _set_tb_host_node_type $1 "PHAN"
}

# unsets host $1 as running the phantom vm
unset_tb_host_as_phantom_vm_node()
{
    _unset_tb_host_node_type $1 "PHAN"
}

# checks if the phantom vm is running on a node
tb_host_phantom_vm_exists()
{
    cut -f5 $TB_HOSTS_FILE | grep -Fqw "PHAN"
}

### TESTBED HOSTS FUNTIONS ###

# checks if nimbus vmm node ($1) is connected to the nimbus head node in the testbed
# a head node must exist in the testbed, or the function will not work properly
is_vmm_connected_to_head()
{
    local vmm_node_name=$(get_tb_host_name $1)
    local head_node_name=$(get_testbed_head_node)
    local head_node_ip=$(get_tb_host_wired_ip $head_node_name)

    ssh $TB_HOSTS_USERNAME@$head_node_ip \
	"[[ \$($TB_HOSTS_NIMBUS_HEAD_DIR/bin/nimbusctl services status | \
             awk '{print \$3}') == \"running\" ]] || \
             $TB_HOSTS_NIMBUS_HEAD_DIR/bin/nimbusctl services start"
    ssh $TB_HOSTS_USERNAME@$head_node_ip \
	"$TB_HOSTS_NIMBUS_HEAD_DIR/bin/nimbus-nodes --list | \
             grep -qw \"hostname.*[[:space:]]$vmm_node_name\""
}

### MISC FUNCTIONS ###

# prompts for y/n answer to $1
prompt_accepted()
{
    while true; do
	read -p "$1 " yn
	case $yn in
            [Yy]* ) return 0; break;;
            [Nn]* ) return 1; break;;
            * ) echo "Please answer yes or no (y/n)";;
	esac
    done 
}

# reboots host $1 and waits for it to start
reboot_and_wait()
{
    local host=$(get_tb_host_wired_ip $1)
    local local_ip=$(ip route get $host | awk '{ print $NF; exit }')

    echo "rebooting host..."
    ssh $TB_HOSTS_USERNAME@$host \
	"sudo sed -i \"/^$/{s/.*/echo 'done' | nc $local_ip $TB_REBOOT_WAIT_PORT\n/;:a;n;ba}\" /etc/rc.local
         sudo reboot"
    nc -l $TB_REBOOT_WAIT_PORT -q 5
    ssh $TB_HOSTS_USERNAME@$host \
	"sudo sed -i \"/echo 'done' | nc $local_ip $TB_REBOOT_WAIT_PORT/d\" /etc/rc.local"
}

# reboots host $1 and waits for it to start only if a reboot is required
reboot_and_wait_if_needed()
{
    local host=$(get_tb_host_wired_ip $1)
    
    if ssh $TB_HOSTS_USERNAME@$host "[ -f /var/run/reboot-required ]"; then
	reboot_and_wait $host
    fi
}

# prints a status bar for a loop using $1 (iteration #) of $2 (total)
print_status_bar()
{
    p_complete=$(($1*100/$2))
    if [[ $p_complete == 100 ]]; then
	echo -ne "\r\033[0Kdone\n"
	return 0
    fi
    stat_bar=""
    for i in $(seq 1 $(($p_complete/2))); do
	stat_bar="$stat_bar#"
    done
    for i in $(seq $(($p_complete/2+1)) 50); do
	stat_bar="$stat_bar."
    done
    echo -ne "\r[$(printf %-50s $stat_bar)][$p_complete%]"
}

# prints an error for the following trap function with exit code $1, line number $2, 
# absolute path of scripts $3, and script arguments $4
# does not print error on exit code 1, as that is used to exit the scripts on purpose
handle_error()
{
    if [[ $1 != 1 ]]; then
	echo "ERROR: An error occurred in $3 on line $2 (exit code $1)"
	echo "To debug, run 'bash -x $3 ${@:4}'"
    fi
}
trap 'handle_error $? $LINENO \
    "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/$(basename $0)" $@' ERR
