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
if [ ! -f "${VENV_DIR}/.requirements_installed" ] || [ "$REQUIREMENTS" -nt "${VENV_DIR}/.requirements_installed" ]; then
    print_info "Installing Python dependencies..."
    pip install --quiet --upgrade pip
    
    if [ -f "$REQUIREMENTS" ]; then
        pip install --quiet -r "$REQUIREMENTS"
    else
        print_warning "Requirements file not found at: $REQUIREMENTS"
        print_warning "Installing minimal dependencies..."
        pip install --quiet selenium webdriver-manager
    fi
    
    # Mark requirements as installed
    touch "${VENV_DIR}/.requirements_installed"
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
