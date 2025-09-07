#!/bin/bash
set -e

source dev-container-features-test-lib

check "testing config in child was untrusted" bash -c 'cd child && mise trust --show | grep "$(pwd): untrusted"'

reportResults
