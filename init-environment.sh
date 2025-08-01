#!/usr/bin/env bash

MONGO_VERSION="8.0.5"
KEYCLOAK_VERSION="26.1.3"

source scripts/my-functions.sh

echo
echo "Starting environment"
echo "===================="

echo
echo "Creating network"
echo "----------------"
docker network create springboot-react-keycloak-net

echo
echo "Starting mongodb"
echo "----------------"

docker run -d \
  --name mongodb \
  -p 27017:27017 \
  --network=springboot-react-keycloak-net \
  mongo:${MONGO_VERSION}

echo
echo "Starting keycloak"
echo "-----------------"

docker run -d \
    --name keycloak \
    -p 8080:8080 \
    -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
    -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
    -e KC_DB=dev-mem \
    --network=springboot-react-keycloak-net \
    quay.io/keycloak/keycloak:${KEYCLOAK_VERSION} start-dev

echo
wait_for_container_log "mongodb" "Waiting for connections"

echo
wait_for_container_log "keycloak" "started in"

echo
echo "Environment Up and Running"
echo "=========================="
echo