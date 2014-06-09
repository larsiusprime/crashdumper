#!/bin/bash
cd "$(dirname "$0")"
open -n -a $(dirname "$0")/runtime/osx/node-webkit.app --args $(dirname "$0")/bin
#."$(dirname "$0")/runtime/osx/node-webkit/Contents/MacOS/node-webkit"
