#!/usr/bin/env bash

# Script to use Yazi as a file picker
# Usage: yazi-file-picker.sh [output_file]

# Create a temporary file to store the selected file path
OUTPUT_FILE="${1:-/tmp/yazi-file-picker-result.txt}"
INITIAL_DIR="${HOME}"

# Clear any previous result
> "$OUTPUT_FILE"

# Run Yazi in a terminal with a special key binding to select files
foot -e bash -c "cd '$INITIAL_DIR' && YAZI_FILE_PICKER_OUTPUT='$OUTPUT_FILE' yazi --picker"

# Wait for the file to be written
for i in {1..10}; do
  if [ -s "$OUTPUT_FILE" ]; then
    break
  fi
  sleep 0.1
done

# Return the selected file path
if [ -s "$OUTPUT_FILE" ]; then
  cat "$OUTPUT_FILE"
  exit 0
else
  echo "No file selected"
  exit 1
fi
