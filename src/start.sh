#!/bin/bash

handler(){
    echo "SIGTERM accept"
    exit 0
}

trap handler SIGTERM

# ============
# main routine
# ============
while :; do
    sleep 3
done
