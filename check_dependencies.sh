#!/bin/bash

# Flutter Linux Dependencies Verification Script
# This script checks if all required packages for Flutter Linux development are installed

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          LINUX DEPENDENCIES VERIFICATION REPORT           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Array of required packages
PACKAGES=(
  "build-essential"
  "cmake"
  "ninja-build"
  "pkg-config"
  "libgtk-3-dev"
  "libsqlite3-dev"
  "libx11-dev"
  "libxext-dev"
  "libxcursor-dev"
  "libxrandr-dev"
  "libxinerama-dev"
  "libxi-dev"
  "libxxf86vm-dev"
  "libudev-dev"
  "libssl-dev"
  "libasound2-dev"
  "libpulse-dev"
  "clang"
)

installed_count=0
missing_count=0
missing_packages=()

# Check each package
for package in "${PACKAGES[@]}"; do
  if dpkg -l | grep -q "^ii  $package"; then
    echo "✓ $package ... INSTALLED"
    ((installed_count++))
  else
    echo "✗ $package ... MISSING"
    ((missing_count++))
    missing_packages+=("$package")
  fi
done

# Print summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                        SUMMARY                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo "Total Packages: ${#PACKAGES[@]}"
echo "Installed: $installed_count"
echo "Missing: $missing_count"
echo ""

# Print status and recommendations
if [ $missing_count -eq 0 ]; then
  echo "✅ ALL PACKAGES INSTALLED! Ready to build Flutter app."
  echo ""
  exit 0
else
  echo "⚠️  MISSING $missing_count PACKAGE(S)! Installation needed."
  echo ""
  echo "Missing packages: ${missing_packages[@]}"
  echo ""
  echo "Run this command to install missing packages:"
  echo "sudo apt-get update && sudo apt-get install -y ${missing_packages[@]}"
  echo ""
  exit 1
fi

