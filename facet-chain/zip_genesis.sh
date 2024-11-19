#!/bin/bash
cd "$(dirname "$0")"  # Change to script's directory
for f in *.json; do
    gzip -f "$f"  # -f forces overwrite of existing .gz files
done
cd - > /dev/null  # Return to original directory
