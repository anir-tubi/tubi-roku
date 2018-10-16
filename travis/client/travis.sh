#!/bin/bash

# Top level build for travis, invoking more generic scripts in /travis
ls -1 ../../build/*.zip | xargs -L1 bash sign.sh
