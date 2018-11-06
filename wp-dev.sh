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

function release {
    # check for local changes
    if [[ `git status --porcelain` ]]; then
        echo "Detected local changes, please commit before release"
        exit 1
    fi

    # ask for version
    echo "Latest Tag: `git describe --abbrev=0 --tags`"
    read -p 'New Version (without prefix, semver only): ' version
    
    # update version in source
    echo "Setting version in styles.css and funtions.php"
    sed -i.bak "s/Version:.*/Version: ${version}/g" src/style.css 
    sed -i.bak "s/initLibsAndMainAssets(.*/initLibsAndMainAssets('${version}');/g" src/functions.php
    rm src/style.css.bak
    rm src/functions.php.bak

    echo ""
    echo "Committing files...."
    git add src/style.css src/functions.php
    git commit -m "Bump version to ${version}"
    
    #create tag and github release
    echo ""
    echo "Pushing tag..."
    git tag "release-${version}"
    git push --tags

    #zip current src
    echo ""
    echo "Creating zip of theme"
    mkdir -p target
    cd src
    zip -q -r ../target/release-$version.zip *
    cd ..
    echo "Pushing github release"
    hub release create -m "v${version}" -a "target/release-${version}.zip" release-$version
    echo ""
    echo "Done, latest release: `hub release -L 1`"
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
        release)
            release
            ;;        
        *)
            echo $"Usage: wp-dev {start|stop|clean|run|cli|bash}"
            echo ""
            exit 1
 
    esac    
}

main $1 $2 ${@:3}