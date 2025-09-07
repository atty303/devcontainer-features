#!/bin/bash
set -e

source dev-container-features-test-lib

check "testing mise is present" bash -c '[ -x ~/.local/bin/mise ]'

reportResults
