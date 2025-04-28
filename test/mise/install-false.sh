#!/bin/bash
#set -e

source dev-container-features-test-lib

check "testing tools command not found" bash -i -c '! command -v bat'
check "can install" mise install
check "testing install was performed" bash -i -c 'command -v bat'

reportResults

