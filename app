#!/bin/bash

# Sets the project name and namespace for re-usability
PROJECT_NAMESPACE='demo'
PROJECT_NAME='php-app'


# Setup variable for needed console color definitions
RED='\033[1;31m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color

# Make sure we can cd back if we need to
originalPWD=$PWD

# Set workdir to executable
cd "${0%/*}"

# Makes sure we use buildkit when building docker images
export DOCKER_BUILDKIT=1

# Displays the help message for the script
function displayHelp() {
    # Be sure to get the filename dynamically
    filename=$(basename "$0")

    # Construct the help screen to be displayed
    printf "${GREEN}Devstack Shell ${YELLOW}version 0.0.2 ${GREEN}\n"
    echo   "----------------------------------------------------------------------------------------------------"
    echo -e "${YELLOW}Usage: ${NC}"
    printf "  %s [option] [arguments]\n" "$filename"
    echo ""
    echo -e "${YELLOW}Options: ${NC}"
    printf "  %-34s %s\n" "up" "Up the environment"
    printf "  %-34s %s\n" "down [--volumes]" "Down the environment (Default: The env upped)"
    printf "  %-34s %s\n" "stackup" "Up the stack"
    printf "  %-34s %s\n" "stackdown" "Down the stack"
    printf "  %-34s %s\n" "build" "Builds all images"
    printf "  %-34s %s\n" "help" "Displays this help screen"
}

# Makes sure network exists
function ensureNetworkExists() {
    if [[ ! $(docker network ls -f name=${PROJECT_NAME} -q) ]]; then
        docker network create ${PROJECT_NAME}
    fi
}

# Calls docker run as the current user to prevent file permissions problems
function dockerRunAsUser() {
    mkdir -p "/tmp/.composer/cache/"
    docker run -u "$(id -u):$(id -g)" -v "/tmp/.composer/cache/:/.composer/cache/" $@
}

function runBuild() {
    echo -e "${GREEN}Building targets"
    echo -e "${GREEN}--------------------------------------- ${NC}"

    echo -e "${YELLOW}Building [base] ${NC}"
    docker build -f docker/php/Dockerfile . --target web -t registry.gitlab.com/${PROJECT_NAMESPACE}/${PROJECT_NAME}/base

    echo -e "${YELLOW}Building [site] ${NC}"
    docker build --progress plain -f sites/web/Dockerfile . --target site -t registry.gitlab.com/${PROJECT_NAMESPACE}/${PROJECT_NAME}/site-web
}

function upDevelopment() {
    echo -e "${GREEN}Upping development environment"
    echo -e "${GREEN}--------------------------------------- ${NC}"

    ensureNetworkExists

    docker-compose -f docker-compose.yml up -d

    echo -e "${GREEN}You should now have a functional Web (Nginx) http://localhost:3010"
    echo -e "${GREEN}You should now have a functional Web (Caddy) http://localhost:3015"
}

function downDevelopment() {
    echo -e "${GREEN}Downing development environment"
    echo -e "${GREEN}--------------------------------------- ${NC}"

    docker-compose -f docker-compose.yml down
}

function runStackUp() {
    echo -e "${GREEN}Upping sites"
    echo -e "${GREEN}--------------------------------------- ${NC}"

    echo -e "${YELLOW}Stack deploy [web] ${NC}"
    docker stack deploy --prune --resolve-image always -c sites/web/docker-compose-prod.yml site-web

    echo -e "${GREEN}Done${NC}"
}

function runStackDown() {
    echo -e "${GREEN}Downing stack"
    echo -e "${GREEN}--------------------------------------- ${NC}"

    echo -e "${YELLOW}Stack remove [web] ${NC}"
    docker stack rm site-web 2>/dev/null || true
}

# Display help if no arguments are passed to the script
if [[ ! $1 ]]; then
    displayHelp
    exit 0
fi

# Case that delegates to the correct function
case "$1" in
    up)
    	shift
        upDevelopment "$@"
        ;;
    down)
    	shift
        downDevelopment "$@"
        ;;
    build)
    	shift
        runBuild "$@"
        ;;
    help)
        displayHelp
        ;;
    stackup)
       runStackUp
       ;;
    stackdown)
       runStackDown
       ;;
    restart)
    	shift
        runRestart "$@"
        ;;
    shell)
    	shift
        runShell "$@"
        ;;
    *)
        echo $"Usage: $0 {help}"
esac

# cd back to the original PWD to return everything back to normal
cd $originalPWD
exit 0
