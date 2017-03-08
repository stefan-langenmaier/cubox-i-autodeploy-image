#!/bin/bash

set -eux

REMOTE_FOLDER="remote"

mkimage -A arm -O linux -T script -C none -n "U-Boot boot script" -d ${REMOTE_FOLDER}/boot.txt ${REMOTE_FOLDER}/boot.scr


#echo "Kill me when no longer needed"
#cd remote
#python2 -m SimpleHTTPServer
