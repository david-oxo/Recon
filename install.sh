#!/bin/bash

read -r -d '' PROGRAMS << EOP
hydra
cewl
curl
dirb
dirsearch
gobuster
nikto
sslscan
whatweb
wkhtmltopdf
EOP

SUDO="sudo"
if [ $(id -u) -eq 0 ] ; then SUDO=" "; fi

$SUDO apt-get update -y
$SUDO apt-get install -y $PROGRAMS

