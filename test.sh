#!/usr/bin/env sh

set -e

BASE_URL="http://home.localhost"

assert_contains() {
  local page="$1"
  local pattern="$2"
  echo "$page" | grep -q "$pattern" || {
    echo "Assertion failed: '$pattern' not found"
    exit 1
  }
}

assert_not_contains() {
  local page="$1"
  local pattern="$2"
  if echo "$page" | grep -q "$pattern"; then
    echo "Assertion failed: '$pattern' SHOULD NOT be present"
    exit 1
  fi
}

run_stack() {
  local compose_file="$1"
  CURRENT_COMPOSE="docker compose -f $compose_file"
  echo "===> Starting stack: $compose_file"
  $CURRENT_COMPOSE up -d --build --wait --remove-orphans || {
    $CURRENT_COMPOSE logs
    $CURRENT_COMPOSE down --volumes --timeout 0
    echo "Unable to start compose: $compose_file"
    exit 1
  }
  $CURRENT_COMPOSE ps
}

stop_stack() {
  local compose_file="$1"
  docker compose -f "$compose_file" down --volumes --timeout 0
}

# ===========================================================================
echo "===> [Test 1] Default entrypoints (web / websecure)"
# ===========================================================================

COMPOSE_FILE="test/default.yaml"
trap "stop_stack $COMPOSE_FILE" EXIT

run_stack "$COMPOSE_FILE"

echo "===> Fetch homepage"
PAGE=$(curl -fs "$BASE_URL")

echo "===> Running assertions"
assert_contains "$PAGE" 'https://doc.traefik.io/traefik/assets/img/traefikproxy-vertical-logo-color.svg'
assert_contains "$PAGE" 'href="http://nginx-host-only.localhost"'
#assert_contains "$PAGE" 'href="/path-only"'
assert_contains "$PAGE" 'href="http://nginx-host-and-path.localhost/path"'
assert_contains "$PAGE" 'href="http://nginx-multiple-host.localhost"'
assert_not_contains "$PAGE" 'href="http://nginx-multiple-host-2.localhost"'
assert_contains "$PAGE" 'href="https://nginx-host-only-secure.localhost"'
assert_contains "$PAGE" 'href="http://nginx-with-alias.localhost"'
assert_contains "$PAGE" 'NginxWithAlias'
assert_not_contains "$PAGE" 'nginx-hidden.localhost'

stop_stack "$COMPOSE_FILE"
trap - EXIT

# ===========================================================================
echo "===> [Test 2] Custom entrypoints (myweb / mywebsecure)"
# ===========================================================================

COMPOSE_FILE="test/custom-entrypoints.yaml"
trap "stop_stack $COMPOSE_FILE" EXIT

run_stack "$COMPOSE_FILE"

echo "===> Fetch homepage"
PAGE=$(curl -fs "$BASE_URL")

echo "===> Running assertions"
# Custom HTTP entrypoint should resolve to http://
assert_contains "$PAGE" 'href="http://nginx-custom-http.localhost"'
# Custom HTTPS entrypoint should resolve to https://
assert_contains "$PAGE" 'href="https://nginx-custom-https.localhost"'
# Standard 'web' entrypoint not in the custom list — must not appear
assert_not_contains "$PAGE" 'nginx-standard-web.localhost'

stop_stack "$COMPOSE_FILE"
trap - EXIT

echo "===> All tests passed"
