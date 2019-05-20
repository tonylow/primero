#! /bin/sh

set -euox
exec "./compose.sh" -f "docker-compose.prod-self-signed.yml" "${@}"
