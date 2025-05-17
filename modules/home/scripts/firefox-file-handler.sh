#!/usr/bin/env bash

# Script to handle file:// URLs from Firefox and open them in Yazi
# Usage: firefox-file-handler.sh file:///path/to/directory

# Extract the path from the URL
url="$1"
path="${url#file://}"

# If it's a directory, open it in Yazi
if [ -d "$path" ]; then
  foot -e yazi "$path"
# If it's a file, open its parent directory in Yazi and select the file
elif [ -f "$path" ]; then
  parent_dir="$(dirname "$path")"
  filename="$(basename "$path")"
  foot -e bash -c "cd '$parent_dir' && yazi -f '$filename'"
else
  # If path doesn't exist, try to open the closest parent directory
  while [ ! -d "$path" ] && [ "$path" != "/" ]; do
    path="$(dirname "$path")"
  done
  
  if [ -d "$path" ]; then
    foot -e yazi "$path"
  else
    # Fallback to home directory if nothing works
    foot -e yazi "$HOME"
  fi
fi
