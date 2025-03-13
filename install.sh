#!/bin/bash

# A5 Feature Generator Installer
echo "========================================="
echo "  A5 Feature Generator Installer"
echo "========================================="
echo "Downloading the feature generator script..."

# Download the script to a temporary file
TMP_FILE="/tmp/generate-feature.sh"
curl -fsSL https://raw.githubusercontent.com/A5-Capital/a5-backend-scaffold/main/generate-feature.sh -o $TMP_FILE

if [ $? -ne 0 ]; then
  echo "Error: Failed to download the script. Please check your internet connection."
  exit 1
fi

# Make it executable
chmod +x $TMP_FILE

if [ $? -ne 0 ]; then
  echo "Error: Failed to make the script executable."
  rm -f $TMP_FILE
  exit 1
fi

echo "Download complete. Running the feature generator..."
echo ""

# Run the script interactively
$TMP_FILE

# Clean up when done
rm -f $TMP_FILE

echo ""
echo "Installation complete. Thank you for using A5 Feature Generator!"