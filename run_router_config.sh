#!/bin/bash

##############################################################################
# Asus Router URL Filter Configuration Script
#
# This script initializes a Python virtual environment (if not already created),
# installs dependencies, and executes the Python script to configure the
# Asus router's URL filtering feature.
#
# Usage:
#   ./run_router_config.sh activate
#   ./run_router_config.sh deactivate
#
# Environment Variables:
#   ROUTER_IP       - Router IP address (default: 192.168.1.1)
#   ROUTER_USERNAME - Router admin username (default: admin)
#   ROUTER_PASSWORD - Router admin password (required)
#
# Example:
#   export ROUTER_PASSWORD="your_password"
#   ./run_router_config.sh activate
##############################################################################

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/venv"
PYTHON_SCRIPT="${SCRIPT_DIR}/asus_router_config.py"
REQUIREMENTS="${SCRIPT_DIR}/requirements.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if action argument is provided
if [ $# -lt 1 ]; then
    print_error "Usage: $0 {activate|deactivate} [additional args]"
    exit 1
fi

ACTION="$1"
shift  # Remove first argument, keep the rest for passing to Python script

# Validate action
if [ "$ACTION" != "activate" ] && [ "$ACTION" != "deactivate" ]; then
    print_error "Invalid action: $ACTION"
    print_error "Action must be 'activate' or 'deactivate'"
    exit 1
fi

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install Python 3 to continue."
    exit 1
fi

print_info "Starting Asus Router URL Filter configuration script"
print_info "Action: $ACTION"

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    print_info "Creating Python virtual environment..."
    python3 -m venv "$VENV_DIR"
    print_info "Virtual environment created at: $VENV_DIR"
else
    print_info "Using existing virtual environment at: $VENV_DIR"
fi

# Activate virtual environment
print_info "Activating virtual environment..."
source "${VENV_DIR}/bin/activate"

# Install/update requirements only if venv was just created or requirements changed
REQUIREMENTS_MARKER="${VENV_DIR}/.requirements_installed"
SHOULD_INSTALL=false

if [ ! -f "$REQUIREMENTS_MARKER" ]; then
    SHOULD_INSTALL=true
elif [ -f "$REQUIREMENTS" ] && [ "$REQUIREMENTS" -nt "$REQUIREMENTS_MARKER" ]; then
    SHOULD_INSTALL=true
fi

if [ "$SHOULD_INSTALL" = true ]; then
    print_info "Installing Python dependencies..."
    pip install --quiet --upgrade pip
    
    if [ -f "$REQUIREMENTS" ]; then
        pip install --quiet -r "$REQUIREMENTS"
    else
        print_warning "Requirements file not found at: $REQUIREMENTS"
        print_warning "Installing minimal dependencies..."
        pip install --quiet selenium webdriver-manager
    fi
    
    # Install geckodriver from Mozilla releases
    print_info "Installing geckodriver from Mozilla releases..."
    GECKODRIVER_VERSION="${GECKODRIVER_VERSION:-v0.36.0}"
    GECKODRIVER_DIR="${VENV_DIR}/bin"
    GECKODRIVER_PATH="${GECKODRIVER_DIR}/geckodriver"
    
    # Detect system architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        GECKODRIVER_ARCH="linux64"
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        GECKODRIVER_ARCH="linux-aarch64"
    elif [ "$ARCH" = "armv7l" ]; then
        GECKODRIVER_ARCH="linux32"
    else
        print_warning "Unsupported architecture: $ARCH, defaulting to linux64"
        GECKODRIVER_ARCH="linux64"
    fi
    
    # Download geckodriver if not already present
    if [ ! -f "$GECKODRIVER_PATH" ]; then
        print_info "Downloading geckodriver ${GECKODRIVER_VERSION} for ${GECKODRIVER_ARCH}..."
        GECKODRIVER_URL="https://github.com/mozilla/geckodriver/releases/download/${GECKODRIVER_VERSION}/geckodriver-${GECKODRIVER_VERSION}-${GECKODRIVER_ARCH}.tar.gz"
        
        # Download to temporary location
        TMP_DIR=$(mktemp -d)
        CURRENT_DIR=$(pwd)
        cd "$TMP_DIR"
        
        DOWNLOAD_SUCCESS=false
        if command -v wget &> /dev/null; then
            if wget -q "$GECKODRIVER_URL" -O geckodriver.tar.gz; then
                DOWNLOAD_SUCCESS=true
            fi
        elif command -v curl &> /dev/null; then
            if curl -sL "$GECKODRIVER_URL" -o geckodriver.tar.gz; then
                DOWNLOAD_SUCCESS=true
            fi
        else
            print_error "Neither wget nor curl is available. Cannot download geckodriver."
            cd "$CURRENT_DIR"
            rm -rf "$TMP_DIR"
            exit 1
        fi
        
        if [ "$DOWNLOAD_SUCCESS" = false ]; then
            print_error "Failed to download geckodriver from: $GECKODRIVER_URL"
            print_error "Please check your internet connection or verify the URL is correct."
            cd "$CURRENT_DIR"
            rm -rf "$TMP_DIR"
            exit 1
        fi
        
        # Extract and install
        if ! tar -xzf geckodriver.tar.gz; then
            print_error "Failed to extract geckodriver archive. The download may be corrupted."
            cd "$CURRENT_DIR"
            rm -rf "$TMP_DIR"
            exit 1
        fi
        
        mkdir -p "$GECKODRIVER_DIR"
        mv geckodriver "$GECKODRIVER_PATH"
        chmod +x "$GECKODRIVER_PATH"
        
        # Cleanup
        cd "$CURRENT_DIR"
        rm -rf "$TMP_DIR"
        
        print_info "Geckodriver installed successfully at: $GECKODRIVER_PATH"
    else
        print_info "Geckodriver already installed at: $GECKODRIVER_PATH"
    fi
    
    # Mark requirements as installed with current timestamp
    touch "$REQUIREMENTS_MARKER"
else
    print_info "Dependencies already installed, skipping installation"
fi

# Check if router password is set
if [ -z "$ROUTER_PASSWORD" ]; then
    print_warning "ROUTER_PASSWORD environment variable is not set!"
    print_warning "The Python script will fail without a password."
fi

# Execute the Python script
print_info "Executing Python script: $PYTHON_SCRIPT"
print_info "Running command: python $PYTHON_SCRIPT $ACTION $@"
echo ""

# Run the Python script with the action and any additional arguments
python "$PYTHON_SCRIPT" "$ACTION" "$@"
EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    print_info "Configuration completed successfully!"
    print_info "URL filtering has been ${ACTION}ed"
else
    print_error "Configuration failed with exit code: $EXIT_CODE"
    print_error "Check the error messages above for details"
fi

# Deactivate virtual environment
deactivate

exit $EXIT_CODE
