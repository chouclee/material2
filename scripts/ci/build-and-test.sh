#!/usr/bin/env bash
set -ex

echo "=======  Starting build-and-test.sh  ========================================"

# Go to project dir
cd $(dirname $0)/../..

# Include sources.
source scripts/ci/sources/mode.sh
source scripts/ci/sources/tunnel.sh

start_tunnel
wait_for_tunnel

if is_lint; then
  $(npm bin)/gulp ci:lint
elif is_e2e; then
  $(npm bin)/gulp ci:e2e
elif is_aot; then
  $(npm bin)/gulp ci:aot
elif is_payload; then
  $(npm bin)/gulp ci:payload
elif is_closure_compiler; then
  ./scripts/closure-compiler/build-devapp-bundle.sh
else
  echo "diff files:"
  for filename in $(git diff --name-only $TRAVIS_BRANCH...HEAD); do
    if ! [[ "$filename" =~ .*\.md ]]; then
      $(npm bin)/gulp ci:test
      break
    fi
  done
fi

# Upload coverage results if those are present.
if [ -f dist/coverage/coverage-summary.json ]; then
  $(npm bin)/gulp ci:coverage
fi

teardown_tunnel
