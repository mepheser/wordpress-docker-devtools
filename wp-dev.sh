#!/bin/bash

DEV_HOME="$(dirname "$(readlink "$0")")"
COMPOSE_FILE="$DEV_HOME/docker-compose.yml"
WORKING_DIRECTORY="${PWD}"
export CONTAINER_PRAEFIX="${PWD##*/}"
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
    case "$1" in
        start)
            start
            ;;
         
        stop)
            stop
            ;;
         
        clean)
            clean
            ;;
        run)
            run $2
            ;;
        cli)
            cli $2 $3 
            ;;
        bash)
            bash
            ;;    
        *)
            echo $"Usage: wp-dev {start|stop|clean|run|cli|bash}"
            echo ""
            exit 1
 
    esac    
}

main $1 $2 ${@:3}