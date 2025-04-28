#!/bin/bash
set -e

source dev-container-features-test-lib

check "testing install was performed" bash -i -c 'command -v bat'

reportResults
