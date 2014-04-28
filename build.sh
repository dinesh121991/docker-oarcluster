#!/bin/bash
set -o errexit

DOCKER=${DOCKER:-docker}
BASEDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
VERSION=$(cat $BASEDIR/version.txt)


fail() {
    echo $@ 1>&2
    exit 1
}

$DOCKER 2> /dev/null || fail "error: Docker ($DOCKER) executable no found. Make sure Docker is installed and/or use the DOCKER variable to set Docker executable."

source $BASEDIR/clean.sh

NODES=("frontend-nfs" "node-nfs" "server-nfs")

# forward OAR version if necessary
for image in "${NODES[@]}"; do
    if [ -f $BASEDIR/images/$image/version.txt ]; then
        if [ ! "$VERSION" == "$(cat $BASEDIR/images/$image/version.txt)" ]; then
            echo "$VERSION" > $BASEDIR/images/$image/version.txt
        fi
    else
        echo "$VERSION" > $BASEDIR/images/$image/version.txt
    fi
done

$DOCKER build --rm -t oarcluster/dnsmasq $BASEDIR/images/dnsmasq/
$DOCKER build --rm -t oarcluster/nfs-server $BASEDIR/images/nfs-server/
$DOCKER build --rm -t oarcluster/nfs-client $BASEDIR/images/nfs-client/

for image in "${NODES[@]}"; do
    $DOCKER build --rm -t oarcluster/$image:${VERSION} $BASEDIR/images/$image/
    $DOCKER tag oarcluster/$image:${VERSION} oarcluster/$image:latest
done
$DOCKER images | grep "<none>" | awk '{print $3}' | xargs -I {} $DOCKER rmi -f {}
