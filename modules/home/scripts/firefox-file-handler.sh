#!/usr/bin/env bash

# Script to handle file:// URLs from Firefox and open them in Yazi
# Usage: firefox-file-handler.sh file:///path/to/directory

# Log the command for debugging
echo "$(date): firefox-file-handler called with argument: $1" >> /tmp/firefox-file-handler.log

# Extract the path from the URL
url="$1"
path="${url#file://}"

echo "$(date): Extracted path: $path" >> /tmp/firefox-file-handler.log

# If it's a directory, open it in Yazi
if [ -d "$path" ]; then
  echo "$(date): Opening directory: $path" >> /tmp/firefox-file-handler.log
  foot -e yazi "$path"
# If it's a file, open its parent directory in Yazi and select the file
elif [ -f "$path" ]; then
  parent_dir="$(dirname "$path")"
  filename="$(basename "$path")"
  echo "$(date): Opening file: $path (parent: $parent_dir, filename: $filename)" >> /tmp/firefox-file-handler.log
  foot -e bash -c "cd '$parent_dir' && yazi -f '$filename'"
else
  echo "$(date): Path doesn't exist, trying to find closest parent directory" >> /tmp/firefox-file-handler.log
  # If path doesn't exist, try to open the closest parent directory
  while [ ! -d "$path" ] && [ "$path" != "/" ]; do
    path="$(dirname "$path")"
    echo "$(date): Trying parent: $path" >> /tmp/firefox-file-handler.log
  done
  
  if [ -d "$path" ]; then
    echo "$(date): Opening closest parent directory: $path" >> /tmp/firefox-file-handler.log
    foot -e yazi "$path"
  else
    echo "$(date): Fallback to home directory" >> /tmp/firefox-file-handler.log
    # Fallback to home directory if nothing works
    foot -e yazi "$HOME"
  fi
fi
