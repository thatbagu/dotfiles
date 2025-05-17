#!/usr/bin/env bash

# Script to integrate Yazi with Firefox's file picker
# This script is called by the GTK file picker when a file is needed

# Log the invocation for debugging
echo "$(date): firefox-custom-file-picker called with args: $@" >> /tmp/firefox-file-picker.log

# Use Yazi to pick a file
SELECTED_FILE=$(yazi-file-picker)

# Check if a file was selected
if [ -n "$SELECTED_FILE" ] && [ -f "$SELECTED_FILE" ]; then
    echo "$(date): Selected file: $SELECTED_FILE" >> /tmp/firefox-file-picker.log
    
    # Copy the selected file path to the clipboard
    echo -n "$SELECTED_FILE" | wl-copy
    
    # Notify the user
    notify-send "File Selected" "The file $SELECTED_FILE has been copied to clipboard. Paste it in the file input field."
    
    # Return success
    exit 0
else
    echo "$(date): No file selected" >> /tmp/firefox-file-picker.log
    notify-send "File Selection Canceled" "No file was selected."
    exit 1
fi
