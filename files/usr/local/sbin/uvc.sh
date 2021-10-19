#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
run-parts --exit-on-error ${SCRIPT_DIR}/uvc.d