#!/bin/bash
export QUICK=0
if [ "$(echo $@ | grep -e " -q" | wc -l)" == "1" ] ; then export QUICK=1 ; fi
args=$(echo $@ | sed -e 's/-q//' -e 's/ //')

if [ "-$args" == "-" ]; then 
    select network in $(ip route | grep -v "default" | awk '{print $1}') ; do 
        select ip in $(nmap -sn $network -oG - | awk '{match($2,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($2,RSTART,RLENGTH); print ip}'); do
        # arp-scan -x $network 
            IP=$ip
            break
        done
        break
    done
    echo $IP
else 
    IP=$args
    if ! [[ $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "$IP is not a valid IP!"
      exit
    fi
fi
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
    
    if [ ! -d $DIR/$SERVICE ]; then return 1 ; fi
    
    echo "[+] $SERVICE"
    for script in $(find $DIR/$SERVICE -type f); do 
        bash $script $IP $PUERTO &
        pids[$!]=$!
        while [ ${#pids[@]} -ge $MAX_THREADS ] ; do
            for pid in ${pids[*]}; do 
                ps --pid $pid > /dev/null 2>&1
                if [ $? -eq 1 ] ; then unset pids[$pid]; fi
            done
            sleep 1
        done
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
    if [ ! -d $DIR/BRUTEFORCE ]; then return 1 ; fi
    
    echo "[!] BRUTEFORCE $SERVICE"
    for script in $(find $DIR/BRUTEFORCE -type f); do 
        bash $script $IP $SERVICE &
        pids[${RANDOM}]=$!
        while [ ${#pids[@]} -ge $MAX_THREADS ] ; do
            for pid in ${pids[*]}; do 
                ps --pid $pid > /dev/null 2>&1
                if [ $? -eq 1 ] ; then unset pids[$pid]; fi
            done
            sleep 1
        done
    done
    # https://stackoverflow.com/questions/356100/how-to-wait-in-bash-for-several-subprocesses-to-finish-and-return-exit-code-0
    # run processes and store pids in array
    # wait for all pids
    for pid in ${pids[*]}; do 
        wait $pid
    done
}

############ MAIN()
export REPORT=$PWD/$IP
if [ ! -d $REPORT ] ; then mkdir -p $REPORT; fi

for port in $(nmap --open -A -sS -T5 -n $IP -p- | grep open |cut -d/ -f1); do
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
unset $QUICK
for SERVICE in $(find $REPORT/ -type f -exec basename {} \; | cut -d- -f1 | sort | uniq) ; do
    if [ ! -d $REPORT/$SERVICE ] ; then mkdir -p $REPORT/$SERVICE ; fi
    find $REPORT/ -type f -iname $SERVICE-* -exec mv -f "{}" "$REPORT/$SERVICE/" \; > /dev/null 2>&1
done
####################

