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

# Always create a runner script because curl | bash doesn't handle interactive input
RUNNER_SCRIPT="$HOME/run-a5-feature-generator.sh"

cat > $RUNNER_SCRIPT << 'EOF'
#!/bin/bash
echo "Running A5 Feature Generator..."
/tmp/generate-feature.sh
EXIT_CODE=$?
rm -f /tmp/generate-feature.sh
echo "Thank you for using A5 Feature Generator!"
exit $EXIT_CODE
EOF

chmod +x $RUNNER_SCRIPT

echo "Download complete."
echo ""
echo "IMPORTANT: To run the interactive feature generator, please use this command:"
echo ""
echo "  $RUNNER_SCRIPT"
echo ""
echo "This will allow you to input all required information interactively."