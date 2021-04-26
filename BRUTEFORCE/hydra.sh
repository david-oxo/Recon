#!/bin/bash

if [ -z ${1+x} ]; then echo "No hay IP"; exit; else IP=$1; fi
if [ -z ${2+x} ]; then echo "No hay SERVICIO"; exit; else SERVICE=$2; fi
SERVICE_U=$(echo $SERVICE | awk '{print toupper($0)}')
SERVICE_L=$(echo $SERVICE | awk '{print tolower($0)}') 

# Configuracion
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [ ! -f $DIR/../config.sh ]; then echo "NO SE PUEDE CARGAR LA CONFIG"; exit; fi
source $DIR/../config.sh
if [ "$BRUTEFORCE" -ne "1" ]; then exit ; fi

# VARIABLES
if [ -z ${REPORT+x} ]; then echo "NO EXISTE REPORT"; exit; fi
if [ -z ${BF_USERDIC+x} ]; then echo "NO EXISTE BF_USERDIC"; exit; fi
if [ -z ${BF_PASSDIC+x} ]; then echo "NO EXISTE BF_PASSDIC"; exit; fi
#
if [ ! -d $REPORT ]; then echo "NO EXISTE REPORT"; exit; fi
if [ ! -f $BF_USERDIC ]; then echo "NO EXISTE BF_USERDIC"; exit; fi
if [ ! -f $BF_PASSDIC ]; then echo "NO EXISTE BF_PASSDIC"; exit; fi

####################

# *(-e nsr  try "n" null password, "s" login as pass and/or "r" reversed login)*
for USER in ${BF_USER[*]} ; do
    if [ -z ${USER+x} ]; then echo "NO EXISTE $USER"; exit; fi
    echo "[#] Lanzando NSR $USER..."
    hydra -I -l $USER -e nsr $IP $SERVICE_L -o $REPORT/$SERVICE_U-BF_NSR-$USER.txt > /dev/null 2>&1 &
    pids[${RANDOM}]=$!
done

# BRUTEFORCE
echo "[#] Lanzando DIC..."
hydra -I -L $BF_USERDIC -P $BF_PASSDIC $IP $SERVICE_L -o $REPORT/$SERVICE_U-BF_DIC.txt > /dev/null 2>&1 &
pids[${RANDOM}]=$!

####################
# https://stackoverflow.com/questions/356100/how-to-wait-in-bash-for-several-subprocesses-to-finish-and-return-exit-code-0
# run processes and store pids in array
# wait for all pids
for pid in ${pids[*]}; do
    #echo "Esperando..." 
    wait $pid
done
