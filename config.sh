#!/bin/bash

# GLOBALES
BRUTEFORCE=0 # 1-YES | 0-NO
FUZZERS=1 # 1-YES | 0-NO

# BF CONFIG

declare -a BF_USER
BF_USER[0]=root
BF_USER[1]=user
BF_USERDIC=/usr/share/seclists/Usernames/top-usernames-shortlist.txt
BF_PASSDIC=/usr/share/wordlists/rockyou.txt

#GOBUSTER
declare -a GOBUSTER_DIC
GOBUSTER_DIC[0]=/usr/share/seclists/Discovery/Web-Content/common.txt
GOBUSTER_DIC[1]=/usr/share/seclists/Discovery/Web-Content/big.txt
GOBUSTER_DIC[2]=/usr/share/seclists/Discovery/Web-Content/directory-list-lowercase-2.3-big.txt
#DIRSEARCH
declare -a DIRSEARCH_DIC
DIRSEARCH_DIC[0]=/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt
DIRSEARCH_DIC[1]=/usr/share/seclists/Discovery/Web-Content/quickhits.txt
DIRSEARCH_DIC[2]=/usr/share/seclists/Discovery/Web-Content/dirsearch.txt
#DIRB
declare -a DIRB_DIC
DIRB_DIC[0]=/usr/share/seclists/Discovery/Web-Content/directory-list-2.3-small.txt
DIRB_DIC[1]=/usr/share/seclists/Discovery/Web-Content/web-mutations.txt
DIRB_DIC[2]=/usr/share/seclists/Discovery/Web-Content/apache.txt

# 

