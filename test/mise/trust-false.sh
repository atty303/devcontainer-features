#!/bin/bash
set -e

source dev-container-features-test-lib

check "testing config was untrusted" bash -c 'mise trust --show | grep "$(pwd): untrusted"'

reportResults
