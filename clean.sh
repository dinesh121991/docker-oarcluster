#!/bin/bash

DOCKER=${DOCKER:-docker}
WORKDIR=/tmp/oarcluster/
BASEDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
VERSION=$(cat $BASEDIR/version.txt)

fail() {
    echo $@ 1>&2
    exit 1
}

$DOCKER 2> /dev/null || fail "error: Docker ($DOCKER) executable no found. Make sure Docker is installed and/or use the DOCKER variable to set Docker executable."

echo "Cleanup old containers"

CONTAINERS=`$DOCKER ps -a | grep oarcluster | awk '{print $NF}' | tr '\n' ' '`
CONTAINERS=($CONTAINERS)
for container in "${CONTAINERS[@]}"; do
    echo "$($DOCKER kill $container) --> Stopped"
done
for container in "${CONTAINERS[@]}"; do
    echo "$($DOCKER rm $container) --> Removed"
done
if [ -d "$WORKDIR" ]; then
    rm -fr "$WORKDIR"
fi

echo "OK"
