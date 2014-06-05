#!/bin/bash
set -e

TARGET="/data"
SRC="/data"

rpcbind &


mkdir -p /data
echo  "Mount NFS shared folder"
mount -t nfs -o rw,user,auto,nfsvers=v3 172.17.42.1:/data /data
