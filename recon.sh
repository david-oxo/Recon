#!/bin/bash
export QUICK=0
export COLORIZE=1

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
    if ! [[ $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] ; then
    if ! [[ $IP =~ ^([a-z0-9\-]+\.){1,2}[a-z]{2,10}$ ]] ; then
      echo "$IP is not a valid IP!"
      exit
    fi
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
function print_console () {
    if [ -z ${1+x} ]; then local COLOR=$Color_Off ; else local COLOR=$1 ; fi
    if [ -z ${2+x} ]; then echo "No hay mensaje"; exit; else local MSG=$2 ; fi
    
    if [ "$COLORIZE" -eq "1" ]; then echo -e $COLOR$MSG$Color_Off ; else echo $MSG ;fi 
}

function letsgo (){
    local SERVICE=$1
    local PUERTO=$2
    
    if [ ! -d $DIR/$SERVICE ]; then return 1 ; fi
    
    print_console $Yellow "[+] $SERVICE"
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
    
    print_console $Red "[!] BRUTEFORCE $SERVICE"
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

print_console $Blue "[!] Lanzando primer escaneo.."

nmap --open -A -sS -sV -T5 -n $IP -p- > "$REPORT/$IP_nmap.txt"
if [ "$COLORIZE" -eq "1" ]; then echo -n -e $Red ; fi 
echo [!] First view:
echo $(cat "$REPORT/$IP_nmap.txt" | grep open | wc -l) ports opened.
cat "$REPORT/$IP_nmap.txt" | grep open
if [ "$COLORIZE" -eq "1" ]; then echo -n -e $Color_Off ; fi 

print_console $Blue "[!] Interactuando con los puertos abiertos..."
for port in $(cat "$REPORT/$IP_nmap.txt" | grep open |cut -d/ -f1); do
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
        print_console $Blue "OTRO: $port"
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

