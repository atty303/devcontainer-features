#!/bin/bash
set -e

source dev-container-features-test-lib

check "testing config in child was trusted" bash -c 'cd child && mise trust --show | grep "$(pwd): trusted"'

reportResults
