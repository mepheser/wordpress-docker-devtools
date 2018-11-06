#!/bin/bash

DEV_HOME="$(dirname "$(readlink "$0")")"
COMPOSE_FILE="$DEV_HOME/docker-compose.yml"
WORKING_DIRECTORY="${PWD}"
CONTAINER_PRAEFIX="${PWD##*/}"
WORDPRESS_CONTAINER="${CONTAINER_PRAEFIX}_wordpress_1"

echo "------------------------------"
echo "COMPOSE_FILE: $COMPOSE_FILE"
echo "WORKING_DIRECTORY: $WORKING_DIRECTORY"
echo "CONTAINER_PRAEFIX: $CONTAINER_PRAEFIX"
echo "WORDPRESS_CONTAINER: $WORDPRESS_CONTAINER"
echo "------------------------------"
echo ""

function start {
    docker-compose -p $CONTAINER_PRAEFIX --project-directory $WORKING_DIRECTORY -f $COMPOSE_FILE up -d
}

function stop {
    docker-compose -p $CONTAINER_PRAEFIX --project-directory $WORKING_DIRECTORY -f $COMPOSE_FILE down
}

function clean {
    docker-compose -p $CONTAINER_PRAEFIX --project-directory $WORKING_DIRECTORY -f $COMPOSE_FILE down -v
}

function run {
    docker run -it --rm \
        --volumes-from $WORDPRESS_CONTAINER \
        --network container:$WORDPRESS_CONTAINER \
        -u=xfs \
        wordpress:cli sh -c /tmp/cli/$1.sh 
}

function cli {
   docker run -it --rm \
        --volumes-from $WORDPRESS_CONTAINER \
        --network container:$WORDPRESS_CONTAINER \
        -u=xfs \
        wordpress:cli wp $1 $2
}

function bash {
   docker run -it --rm \
        --volumes-from $WORDPRESS_CONTAINER \
        --network container:$WORDPRESS_CONTAINER \
        -u=xfs \
        wordpress:cli bash
}


function main {
    if [ $1 = "start" ]
    then
        start
    fi

    if [ $1 = "stop" ]
    then
        stop
    fi

    if [ $1 = "clean" ]
    then
        clean   
    fi

    if [ $1 = "run" ]
    then
       run $2
    fi

    if [ $1 = "cli" ]
    then
        cli $2 $3 
        exit;
    fi

    if [ $1 = "bash" ]
    then
        bash
    fi
}

main $1 $2 ${@:3}