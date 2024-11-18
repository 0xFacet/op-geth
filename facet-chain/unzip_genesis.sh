#!/bin/bash
cd "$(dirname "$0")"  # Change to script's directory
for f in *.json.gz; do [ -f "${f%.gz}" ] || gunzip -k "$f"; done
cd - > /dev/null  # Return to original directory
