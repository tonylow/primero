#!/bin/bash

# This helper file contains shortcuts for commonly used commands.

# Deletes all containers, builds primero, and starts it
prim_make_clean() {
  set -x
  source ../venv/bin/activate;
  printf "removing all docker containers and building dev\\n"
  docker stop "$(docker ps -a -q)"
  docker rm "$(docker ps -a -q)"
  docker volume prune -f
  ./build.sh dev && ./compose.dev.sh up
}

# Find the dev container and enter it
# pass any arguments to the container, otherwise default to running bash
prim_enter_dev_container() {
  set +e
  docker exec -it "$(docker ps -f name=development -q)" "${@-bash}"
  set -e
}
# Start dev container and run bash
prim_start_dev_container() {
  set +e
  ./compose.dev.sh run --rm development "${@-bash}"
  set -e
}
# stop containers
prim_down_dev_container() {
  ./compose.dev.sh down
}
# remove containers
prim_rm_dev_container() {
  ./compose.dev.sh rm
}

source source.sh

set +u
case $1 in
  run)
    shift
    prim_start_dev_container "$@"
    ;;
  up)
    shift
    ./compose.dev.sh up "$@"
    ;;
  enter)
    shift
    prim_enter_dev_container "$@"
    ;;
  down)
    shift
    prim_down_dev_container
    ;;
  rm)
    shift
    prim_rm_dev_container
    ;;
  clean)
    shift
    prim_make_clean
    ;;
  *)
    printf "Unrecognized command: %s\\n" "$@"
    printf "Usage: start, rm, down, up, enter, clean\\n"
    ;;
esac
set -u
