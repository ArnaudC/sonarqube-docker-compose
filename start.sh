#!/bin/bash
#-- Usage:
#   ./start.sh          # List all commands
#   ./start.sh init     # Create a dev env from scratch
set -ex

help() {
    echo "Usage : sh start.sh [argument]"
    echo " init_or_reset   Initialize the project from scratch. Recreate db structure, play all migrations, insert staging fixtures."
    echo " restart         A Simple restart."
    echo " start           Start SonarQube after init_or_reset."
    echo " stop            Stop SonarQube after init_or_reset."
    echo " gitRemember     Remember git creds."
    echo " upgrade         Upgrade sonarqube instance. Warning: ensure backups are done before."
    echo " logs            View logs."
}

setPermissionsForElasticSearch() {
    sudo sysctl -w vm.max_map_count=524288;
    sudo sysctl -w fs.file-max=131072;
}

init_or_reset() {
    cd $INSTALL_DIR
    setPermissionsForElasticSearch
    docker-compose down --rmi all --volumes --remove-orphans
    docker system prune --all --force
    docker volume prune -f
    sudo rm -rf /var/data/sonarqube*
    sudo rm -rf /var/data/postgresql*
    start
    logs
}

restart() {
    cd $INSTALL_DIR
    setPermissionsForElasticSearch
    stop
    start
    logs
}

stop() {
    cd $INSTALL_DIR
    docker-compose down
}

start() {
    cd $INSTALL_DIR
    docker-compose up -d
}

gitRememberCreds() {
    git config --global credential.helper store
    git pull
}

upgrade() {
    cd $INSTALL_DIR
    stop
    df -h
    docker image prune -a -f
    docker-compose pull
    start
    df -h
    echo "Go to https://sonarqube.icm-institute.org/setup and follow the setup instructions."
    logs
}

logs() {
    docker-compose logs -ft
}

main() {
    if [ $# -eq 0 ]; then # No argument
        set +x
        help
        exit 1
    fi

    if [ ! -f .env ]; then
        echo ".env not found : cp .env.tpl .env"
        cp .env.tpl .env
    fi
    source ./.env

    cmd="$1 ${@:2}" # $1 is the command and ${@:2} is the list of arguments
    $cmd
}

# Main entry point
main "$@"
