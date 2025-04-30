#!/bin/bash

# Usage: ./scan_adf_to_pdf.sh "device-name" "ADF Source" "output.pdf" "/path/to/consume/folder"

DEVICE_NAME="$1"
ADF_SOURCE="${2:-ADF Front}"       # Default to "ADF Front" if not specified
PAPERLESS_CONSUME_FOLDER=${3:-"/usr/src/paperless/consume"} # Paperless-ngx consume folder (modify this path based on your setup)
OUTPUT_FILE="${4:-output.pdf}"     # Default to "output.pdf" if not specified

# Temporary directory for TIFF files
TEMP_DIR="/tmp/scan"

# Create the temporary directory if it doesn't exist
mkdir -p "$TEMP_DIR"

if [ -z "$DEVICE_NAME" ]; then
  echo "Usage: $0 \"device-name\" [ADF Source] [output.pdf] /path/to/consume/folder"
  exit 1
fi

# Step 1: Scan pages using ADF
echo "Scanning from device: $DEVICE_NAME using source: $ADF_SOURCE..."

scanimage --device-name="$DEVICE_NAME" \
          --batch --format=tiff \
          --source="$ADF_SOURCE" \
          --resolution 300 \
          --output-file="$TEMP_DIR/out%03d.tiff"  # Store TIFFs in /tmp/scan

# Step 2: Convert TIFFs to PDF
OUTPUT_PDF="$PAPERLESS_CONSUME_FOLDER/$OUTPUT_FILE"  # Save PDF to Paperless-ngx consume folder
echo "Converting to PDF: $OUTPUT_PDF..."
img2pdf "$TEMP_DIR/out"*.tiff -o "$OUTPUT_PDF"

# Step 3: Clean up temporary TIFF files
echo "Cleaning up temporary files..."
rm "$TEMP_DIR/out"*.tiff

echo "✅ Scanning complete! Output saved to: $OUTPUT_PDF"
