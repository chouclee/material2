#!/usr/bin/env bash
set -ex

echo "=======  Starting build-and-test.sh  ========================================"

# Go to project dir
cd $(dirname $0)/../..

# Include sources.
source scripts/ci/sources/mode.sh
source scripts/ci/sources/tunnel.sh

# Get commit diff
if [[ $TRAVIS_PULL_REQUEST = "false" ]]; then 
  echo $TRAVIS_COMMIT_RANGE
  diff=$(git diff --name-only $TRAVIS_COMMIT_RANGE)
else
  diff=$(git diff --name-only $TRAVIS_BRANCH...HEAD)
fi

# Check if tests can be skipped
skip_tests=true
for filename in $diff; do
  echo $filename
  if ! [[ $filename =~ .*\.md ]]; then
    skip_tests=false
    break
  fi
done

if $skip_tests && (is_e2e || is_unit); then
  exit 0;
fi

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
elif is_unit; then
  $(npm bin)/gulp ci:test
fi

# Upload coverage results if those are present.
if [ -f dist/coverage/coverage-summary.json ]; then
  $(npm bin)/gulp ci:coverage
fi

teardown_tunnel
