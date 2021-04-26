#!/bin/bash

if [ -z ${1+x} ]; then echo "No hay IP"; exit; else IP=$1; fi
if [ -z ${2+x} ]; then echo "No hay PUERTO"; exit; else PORT=$2; fi

# Configuracion
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [ ! -f $DIR/../config.sh ]; then echo "NO SE PUEDE CARGAR LA CONFIG"; exit; fi
source $DIR/../config.sh

# VARIABLES
if [ -z ${BF_USER+x} ]; then echo "NO EXISTE BF_USER"; exit; fi
if [ -z ${BF_USERDIC+x} ]; then echo "NO EXISTE BF_USERDIC"; exit; fi
if [ -z ${BF_PASSDIC+x} ]; then echo "NO EXISTE BF_PASSDIC"; exit; fi
#
if [ ! -d $REPORT ]; then echo "NO EXISTE REPORT"; exit; fi
if [ ! -f $BF_USERDIC ]; then echo "NO EXISTE BF_USERDIC"; exit; fi
if [ ! -f $BF_PASSDIC ]; then echo "NO EXISTE BF_PASSDIC"; exit; fi

####################
if [ -z ${REPORT+x} ]; then
    REPORT=$DIR/$IP
    if [ ! -d $REPORT ] ; then mkdir -p $REPORT; fi
fi
SERVICE_U=$(basename $DIR | awk '{print toupper($0)}')
SERVICE_L=$(basename $DIR | awk '{print tolower($0)}')
####################

nikto -update > /dev/null 2>&1 
# 
echo "[-] Lanzando nikto ..."
nikto -host http://$IP:$PORT -o $REPORT/$SERVICE_U-NIKTO_$PORT.txt > /dev/null 2>&1 &
pids[${RANDOM}]=$!

####################
# https://stackoverflow.com/questions/356100/how-to-wait-in-bash-for-several-subprocesses-to-finish-and-return-exit-code-0
# run processes and store pids in array
# wait for all pids
for pid in ${pids[*]}; do
    #echo "Esperando..." 
    wait $pid
done
