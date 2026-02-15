#!/usr/bin/env sh

set -e

COMPOSE="docker compose -f test-docker-composer.yaml"
COMPOSE_STOP="$COMPOSE down --volumes --timeout 0"
BASE_URL="http://home.localhost"

echo "===> Starting stack"
$COMPOSE up -d --build --wait --remove-orphans || {
    $COMPOSE logs
    $COMPOSE_STOP
  echo "Unable to start compose"
}
$COMPOSE ps

echo "===> Fetch homepage"
PAGE=$(curl -fs "$BASE_URL")

echo "===> Running assertions"

assert_contains() {
  echo "$PAGE" | grep -q "$1" || {
    echo "Assertion failed: '$1' not found"
    $COMPOSE_STOP
    exit 1
  }
}

assert_not_contains() {
  if echo "$PAGE" | grep -q "$1"; then
    echo "Assertion failed: '$1' SHOULD NOT be present"
    $COMPOSE_STOP
    exit 1
  fi
}

# to perform manual checks
# sleep 100

assert_contains 'https://doc.traefik.io/traefik/assets/img/traefikproxy-vertical-logo-color.svg'
assert_contains 'href="http://nginx-host-only.localhost"'
#assert_contains 'href="/path-only"'
assert_contains 'href="http://nginx-host-and-path.localhost/path"'
assert_contains 'href="http://nginx-multiple-host.localhost"'
assert_not_contains 'href="http://nginx-multiple-host-2.localhost"'
assert_contains 'href="https://nginx-host-only-secure.localhost"'
assert_contains 'href="http://nginx-with-alias.localhost"'
assert_contains 'NginxWithAlias'
assert_not_contains 'nginx-hidden.localhost'


echo "===> Tests passed"

echo "===> Stopping stack"
$COMPOSE_STOP

echo "===> Done"
