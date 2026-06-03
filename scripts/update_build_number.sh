#!/bin/bash
# scripts/update_build_number.sh

# Get current directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_FILE="$DIR/../Near.xcodeproj/project.pbxproj"

# Generate timestamp (YYMMDDHHMM)
TIMESTAMP=$(date "+%y%m%d%H%M")

# Update project.pbxproj
if [ -f "$PROJECT_FILE" ]; then
    # On macOS, sed requires an empty string for the -i flag to edit in-place
    sed -i '' -E "s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = $TIMESTAMP;/g" "$PROJECT_FILE"
    echo "Successfully updated build number to $TIMESTAMP in project.pbxproj"
else
    echo "Error: project.pbxproj not found at $PROJECT_FILE"
    exit 1
fi
