#!/bin/bash

# ZMK Build Script for Lily58
set -e

# Change to script directory
cd "$(dirname "$0")"

# Setup Python environment and west
setup_python_environment() {
    echo "Setting up Python environment..."
    
    # Create virtual environment if it doesn't exist
    if [ ! -d ".venv" ]; then
        echo "Creating Python virtual environment..."
        python3 -m venv .venv
    fi
    
    # Activate virtual environment
    source .venv/bin/activate
    
    # Install/upgrade pip
    pip install --upgrade pip
    
    # Install west if not already installed
    if ! command -v west &> /dev/null; then
        echo "Installing west..."
        pip install west
    fi
    
    # Install essential build dependencies
    echo "Installing build dependencies..."
    pip install setuptools protobuf grpcio-tools pyelftools PyYAML pykwalify canopen packaging progress psutil pylink-square pyserial requests anytree intelhex
    
    echo "Python environment ready"
}

# Setup environment variables
setup_environment() {
    export ZEPHYR_BASE="$(pwd)/zephyr"
    
    # Find Zephyr SDK
    for sdk_path in "$HOME/zephyr-sdk-0.16.8" "/opt/zephyr-sdk" "/usr/local/zephyr-sdk"; do
        if [ -d "$sdk_path" ]; then
            export ZEPHYR_SDK_INSTALL_DIR="$sdk_path"
            break
        fi
    done
    
    if [ -z "$ZEPHYR_SDK_INSTALL_DIR" ]; then
        echo "Error: Zephyr SDK not found"
        echo "Install from: https://github.com/zephyrproject-rtos/sdk-ng/releases"
        exit 1
    fi
    
    # Set CMake paths
    zephyr_cmake_dir="$ZEPHYR_BASE/share/zephyr-package/cmake"
    if [ -d "$zephyr_cmake_dir" ]; then
        export Zephyr_DIR="$zephyr_cmake_dir"
        export CMAKE_PREFIX_PATH="$(dirname "$zephyr_cmake_dir")"
    fi
}

# Initialize or update west workspace
setup_west() {
    # Ensure we're in the virtual environment
    source .venv/bin/activate
    
    if [ ! -d "zmk" ]; then
        echo "Initializing west workspace..."
        west init -l config
        west update
    else
        echo "Updating west workspace..."
        west update
    fi
}

# Build firmware for both halves
build_firmware() {
    # Ensure we're in the virtual environment
    source .venv/bin/activate
    
    # Clean previous build
    [ -d "out" ] && rm -rf out
    
    # Build configurations
    builds=(
        "left:nice_nano_v2:lily58_left nice_view_adapter nice_view:studio-rpc-usb-uart"
        "right:nice_nano_v2:lily58_right nice_view_adapter nice_view:"
    )
    
    mkdir -p firmware
    
    for build_config in "${builds[@]}"; do
        IFS=':' read -r name board shield snippet <<< "$build_config"
        
        echo "Building $name side..."
        
        cmd=(west build -s zmk/app -b "$board" -d "out/$name")
        
        # Add snippet if specified
        [ -n "$snippet" ] && cmd+=(-S "$snippet")
        
        # Add shield and config
        cmd+=(-- "-DSHIELD=$shield" "-DZMK_CONFIG=$(pwd)/config")
        
        "${cmd[@]}"
        
        # Copy firmware
        src="out/$name/zephyr/zmk.uf2"
        dst="firmware/lily58_$name.uf2"
        
        if [ -f "$src" ]; then
            cp "$src" "$dst"
            echo "Created: $dst"
        else
            echo "Error: Firmware not found at $src"
            exit 1
        fi
    done
}

# Main execution
setup_python_environment
setup_environment
setup_west
build_firmware

echo "Build complete"