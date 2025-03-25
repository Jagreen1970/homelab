#!/bin/bash
# Format resource report for better readability

REPORT_FILE="../report.txt"
SUMMARY_FILE="../resource_summary.txt"

if [ ! -f "$REPORT_FILE" ]; then
  echo "Error: Report file not found. Please run the report_resources.yml playbook first."
  exit 1
fi

# Display summary first
if [ -f "$SUMMARY_FILE" ]; then
  echo "==============================================================================="
  echo "                         HOMELAB RESOURCE SUMMARY                              "
  echo "==============================================================================="
  echo ""
  cat "$SUMMARY_FILE"
  echo ""
  echo "==============================================================================="
  echo "                         DETAILED HOST REPORTS                                 "
  echo "==============================================================================="
fi

# Format and display the detailed report with colors
cat "$REPORT_FILE" | sed -E \
  -e 's/^(==+)$/\x1B[36m\1\x1B[0m/g' \
  -e 's/^(Host: .*)$/\x1B[1;32m\1\x1B[0m/g' \
  -e 's/^(CPU:|Memory:|Disk:|Network:|Docker:|Kubernetes:|System Temperature:)$/\x1B[1;33m\1\x1B[0m/g' \
  -e 's/(Temperature: [0-9]+)°C/\x1B[1;31m\1°C\x1B[0m/g' \
  -e 's/(Load averages:.*)$/\x1B[1;34m\1\x1B[0m/g' \
  -e 's/(Free|Available): ([0-9.]+[GM])/\x1B[1;32mFree: \2\x1B[0m/g' \
  -e 's/(Used): ([0-9.]+[GM])/\x1B[1;31mUsed: \2\x1B[0m/g'

echo ""
echo "Report files saved to:"
echo " - Full report: $REPORT_FILE"
echo " - Summary: $SUMMARY_FILE"