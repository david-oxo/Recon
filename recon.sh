#!/bin/bash

if [ -z ${1+x} ]; then 
    select network in $(ip route | grep -v "default" | awk '{print $1}') ; do 
        select ip in $(nmap -sn $network -oG - | awk '{match($2,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($2,RSTART,RLENGTH); print ip}'); do
            IP=$ip
            break
        done
        break
    done
    echo $IP
else IP=$1 ; fi
clear
####################

if [ -z ${IP+x} ]; then exit ; fi 
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Configuracion
if [ ! -f $DIR/config.sh ]; then echo "NO SE PUEDE CARGAR LA CONFIG"; exit; fi
source $DIR/config.sh

################FUNC()
function letsgo (){
    local SERVICE=$1
    local PUERTO=$2
    
    if [ ! -d $PWD/$SERVICE ]; then return 1 ; fi
    
    echo "[+] $SERVICE"
    for script in $(find $PWD/$SERVICE -type f); do 
        bash $script $IP $PUERTO &
        pids[${RANDOM}]=$!
    done
    # https://stackoverflow.com/questions/356100/how-to-wait-in-bash-for-several-subprocesses-to-finish-and-return-exit-code-0
    # run processes and store pids in array
    # wait for all pids
    for pid in ${pids[*]}; do 
        wait $pid
    done
}

function BFORCE (){
    local SERVICE=$1
    if [ "${BRUTEFORCE}" -ne "1" ]; then return 1 ; fi 
    if [ ! -d $PWD/BRUTEFORCE ]; then return 1 ; fi
    
    echo "[!] BRUTEFORCE $SERVICE"
    for script in $(find $PWD/BRUTEFORCE -type f); do 
        bash $script $IP $SERVICE &
        pids[${RANDOM}]=$!
    done
    # https://stackoverflow.com/questions/356100/how-to-wait-in-bash-for-several-subprocesses-to-finish-and-return-exit-code-0
    # run processes and store pids in array
    # wait for all pids
    for pid in ${pids[*]}; do 
        wait $pid
    done
}

############ MAIN()
export REPORT=$DIR/$IP
if [ ! -d $REPORT ] ; then mkdir -p $REPORT; fi

for port in $(nmap --open -T5 -n $IP -p- | grep open |cut -d/ -f1); do
    case $port in
    # FTP / TFTP
    "21" | "69")
        letsgo "FTP" "$port"
        BFORCE "FTP"
        ;;
    # SSH
    "22")
        letsgo "SSH" "$port"
        BFORCE "SSH" 
        ;;
    # HTTP
    "80" | "443" | "8000"| "8080" )
        letsgo "HTTP" "$port"
        ;;
    # Matching with invalid data
    *)
        echo "OTRO: $port"
        #break
        ;;
    esac
done

# Reorganizar logs
for SERVICE in $(find $REPORT/ -type f -exec basename {} \; | cut -d- -f1 | sort | uniq) ; do
    if [ ! -d $REPORT/$SERVICE ] ; then mkdir -p $REPORT/$SERVICE ; fi
    find $REPORT/ -type f -exec mv -f "{}" "$REPORT/$SERVICE/" \; > /dev/null 2>&1
done
####################

