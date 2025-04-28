#!/bin/bash
set -e

source dev-container-features-test-lib

check "testing config was trusted" bash -c '[ -x /tmp/mise ]'

reportResults
