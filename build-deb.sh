#!/bin/sh -e

docker build -t darkmagus/build-unity-lts .

docker run --rm -e USERID=$(id -u $USER) -e GROUPID=$(id -g $USER) -v $(pwd)/:/build darkmagus/build-unity-lts
