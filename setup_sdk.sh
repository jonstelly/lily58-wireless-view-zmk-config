#!/bin/bash

# Zephyr SDK Setup Script
# This script downloads and installs the Zephyr SDK required for ZMK builds

set -e

ZEPHYR_SDK_VERSION="0.16.8"
INSTALL_DIR="$HOME/zephyr-sdk-$ZEPHYR_SDK_VERSION"

echo "🔧 Zephyr SDK Setup for ZMK"
echo "=========================="

# Check if SDK is already installed
if [ -d "$INSTALL_DIR" ]; then
    echo "✅ Zephyr SDK $ZEPHYR_SDK_VERSION already installed at $INSTALL_DIR"
    exit 0
fi

echo "📥 Downloading Zephyr SDK $ZEPHYR_SDK_VERSION..."

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        SDK_ARCH="x86_64"
        ;;
    aarch64|arm64)
        SDK_ARCH="aarch64"
        ;;
    *)
        echo "❌ Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Download SDK
SDK_FILE="zephyr-sdk-$ZEPHYR_SDK_VERSION"_linux-"$SDK_ARCH"_minimal.tar.xz
SDK_URL="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v$ZEPHYR_SDK_VERSION/$SDK_FILE"

cd ~
wget -O "$SDK_FILE" "$SDK_URL"

echo "📦 Extracting SDK..."
tar xf "$SDK_FILE"

echo "🔧 Setting up SDK..."
cd "$INSTALL_DIR"
./setup.sh -t arm-zephyr-eabi

# Cleanup
rm ~/"$SDK_FILE"

echo "✅ Zephyr SDK installed successfully!"
echo "📍 Location: $INSTALL_DIR"
echo ""
echo "You can now run the ZMK build script."