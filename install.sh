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

echo "Download complete."
echo ""

# Check if we're running in a pipe
if [ -t 0 ]; then
  # Terminal is interactive, run the script directly
  echo "Running the feature generator interactively..."
  $TMP_FILE
else
  # We're in a pipe, create a new script to run later
  RUNNER_SCRIPT="$HOME/run-a5-feature-generator.sh"
  
  cat > $RUNNER_SCRIPT << 'EOF'
#!/bin/bash
echo "Running A5 Feature Generator..."
/tmp/generate-feature.sh
rm -f /tmp/generate-feature.sh
echo "Thank you for using A5 Feature Generator!"
EOF

  chmod +x $RUNNER_SCRIPT
  
  echo "IMPORTANT: The script cannot run interactively when piped directly to bash."
  echo "A runner script has been created at: $RUNNER_SCRIPT"
  echo ""
  echo "Please run this command to start the interactive feature generator:"
  echo ""
  echo "  $RUNNER_SCRIPT"
  echo ""
fi

# Don't remove the temp file if we created a runner script
if [ -t 0 ]; then
  # Clean up when done
  rm -f $TMP_FILE
fi

if [ -t 0 ]; then
  echo ""
  echo "Installation complete. Thank you for using A5 Feature Generator!"
fi