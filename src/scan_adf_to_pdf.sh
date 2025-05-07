#!/bin/bash

# Usage: ./scan_adf_to_pdf.sh "device-name" "ADF Source" "/path/to/consume/folder"

DEVICE_NAME="$1"
ADF_SOURCE="${2:-Automatic Document Feeder(centrally aligned)}"
PAPERLESS_CONSUME_FOLDER=${3:-"/opt/paperless/consume"} # Paperless-ngx consume folder

# Generate the output file name based on the current date and time
TIMESTAMP=$(date +"%Y-%m-%d-%H%M")
OUTPUT_FILE="Scan-${TIMESTAMP}.pdf"

# Temporary directory for TIFF files
TEMP_DIR="/tmp/scan"

# Create the temporary directory if it doesn't exist
mkdir -p "$TEMP_DIR"

if [ -z "$DEVICE_NAME" ]; then
  echo "Usage: $0 \"device-name\" [ADF Source] /path/to/consume/folder"
  exit 1
fi

# Step 1: Scan pages using ADF
echo "📥 Scanning from device: $DEVICE_NAME using source: $ADF_SOURCE..."

if ! scanimage --device-name="$DEVICE_NAME" \
               --batch="$TEMP_DIR/out%03d.tiff" --format=tiff \
               --source="$ADF_SOURCE" \
               --resolution 300; then
  echo "❌ Scan failed. Possibly empty ADF."
  exit 2
fi

if ! ls "$TEMP_DIR"/out*.tiff 1>/dev/null 2>&1; then
  echo "❌ No scanned pages found. Maybe the ADF is empty?"
  exit 3
fi

# Step 2: Convert TIFFs to PDF
OUTPUT_PDF="$PAPERLESS_CONSUME_FOLDER/$OUTPUT_FILE"
echo "Converting to PDF: $OUTPUT_PDF..."
if ! img2pdf "$TEMP_DIR/out"*.tiff -o "$OUTPUT_PDF";then
  echo "❌ Error creating PDF - File"
  exit 4
fi

# Step 3: Clean up temporary TIFF files
echo "Cleaning up temporary files..."
rm "$TEMP_DIR/out"*.tiff

echo "✅ Scanning complete! Output saved to: $OUTPUT_PDF"
