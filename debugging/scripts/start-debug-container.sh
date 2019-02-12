#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

set -e

source $(dirname $0)/version

ARCH=${ARCH:-"amd64"}
SUFFIX=""
[ "${ARCH}" != "amd64" ] && SUFFIX="_${ARCH}"

TAG=${TAG:-${VERSION}${SUFFIX}}
if echo $TAG | grep -q dirty; then
    TAG=dev
fi
REPO=${REPO:-rancher}

# If there is already a debugger container running, stop and remove it.
echo "Killing debugger..."
debuggerId=$(docker ps -qf "name=debugger")
if [ ! -z $debuggerId ]; then
        docker exec $debuggerId /go/src/github.com/rancher/rancher/package/debugger/kill-debugger.sh || true
fi

echo "Removing previous debug container..."
debuggerId=$(docker ps -aqf "name=debugger")
if [ ! -z $debuggerId ]; then
	docker rm -f $debuggerId
fi

ROOT=$(dirname $DIR)

# Start new debug container. Mount a few directories of the $GOPATH into the container so we don't have to copy
# things around.
echo "Starting debug container..."
docker run -d -p 80:80 -p 443:443 -p 2345:2345 --name debugger --privileged  \
	-v /go/bin:/go/bin2 \
	-v $ROOT/:/go/src/github.com/rancher/rancher \
	--entrypoint /go/src/github.com/rancher/rancher/package/debugger/start-debugger.sh \
	rancher/rancher:${TAG}

echo "Debug container started"