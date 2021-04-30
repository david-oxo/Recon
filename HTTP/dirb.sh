#!/bin/bash

if [ -z ${1+x} ]; then echo "No hay IP"; exit; else IP=$1; fi
if [ -z ${2+x} ]; then echo "No hay PUERTO"; exit; else PORT=$2; fi

# Configuracion
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [ ! -f $DIR/../config.sh ]; then echo "NO SE PUEDE CARGAR LA CONFIG"; exit; fi
source $DIR/../config.sh

if [ "${FUZZERS}" -ne "1" ]; then exit ; fi 

####################
if [ -z ${REPORT+x} ]; then
    REPORT=$DIR/$IP
    if [ ! -d $REPORT ] ; then mkdir -p $REPORT; fi
fi
SERVICE_U=$(basename $DIR | awk '{print toupper($0)}')
SERVICE_L=$(basename $DIR | awk '{print tolower($0)}')
####################

# 
for DICCIONARIO in ${DIRB_DIC[*]} ; do
    if [ -z ${DICCIONARIO+x} ]; then echo "NO EXISTE $DICCIONARIO"; exit; fi
    if [ ! -f $DICCIONARIO ]; then echo "NO EXISTE $DICCIONARIO"; exit; fi
    DICNAME=$(basename $DICCIONARIO | awk '{print tolower($0)}')
    echo "[=] Lanzando dirb $DICNAME..."
    dirb http://$IP:$PORT/ "$DICCIONARIO" -l -r -S -X ",.txt,.html,.php,.asp,.aspx,.jsp" -o "$REPORT/$SERVICE_U-DIRB-$PORT-$DICNAME" > /dev/null 2>&1 &
    pids[${RANDOM}]=$!
    #sleep 30     
done
####################
# https://stackoverflow.com/questions/356100/how-to-wait-in-bash-for-several-subprocesses-to-finish-and-return-exit-code-0
# run processes and store pids in array
# wait for all pids
for pid in ${pids[*]}; do
    #echo "Esperando..." 
    wait $pid
done
