#!/usr/bin/env bash

# scripts/setup_env.sh

# Exit immediately if a command exits with a non-zero status
set -e


# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Default options
INSTALL_FLUTTER=true
INSTALL_ANDROID=true
INSTALL_VSCODE=true
FORCE_UPDATE=false
FLUTTER_CHANNEL="stable"
DRY_RUN=false

# Default values
FLUTTER_INSTALL_DIR="$HOME/development"
ANDROID_SDK_ROOT="$HOME/Android/Sdk"

# Usage function
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help                 Show this help message and exit"
    echo "  -c, --channel CHANNEL      Specify Flutter channel (stable, beta, dev)"
    echo "      --flutter-dir DIR      Specify Flutter installation directory"
    echo "      --android-sdk DIR      Specify Android SDK root directory"
    echo "      --no-flutter           Skip Flutter installation"
    echo "      --no-android           Skip Android SDK installation"
    echo "      --no-vscode            Skip Visual Studio Code installation"
    echo "      --update               Force update existing installations"
    echo "      --dry-run              Simulate the script without making changes"
    exit 1
}

# Parse command-line options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        -c|--channel)
            if [[ -n $2 ]]; then
                FLUTTER_CHANNEL=$2
                shift
            else
                log_error "Error: --channel requires a value"
                exit 1
            fi
            ;;
        --flutter-dir)
            if [[ -n $2 ]]; then
                FLUTTER_INSTALL_DIR=$2
                shift
            else
                log_error "Error: --flutter-dir requires a value"
                exit 1
            fi
            ;;
        --android-sdk)
            if [[ -n $2 ]]; then
                ANDROID_SDK_ROOT=$2
                shift
            else
                log_error "Error: --android-sdk requires a value"
                exit 1
            fi
            ;;
        --no-flutter) INSTALL_FLUTTER=false ;;
        --no-android) INSTALL_ANDROID=false ;;
        --no-vscode) INSTALL_VSCODE=false ;;
        --update) FORCE_UPDATE=true ;;
        --dry-run) DRY_RUN=true ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
    shift
done

# Function to display current settings
display_settings() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}       Development Setup Settings       ${NC}"
    echo -e "${GREEN}========================================${NC}"
    printf "${YELLOW}%-30s${CYAN}%s${NC}\n" "Install Flutter SDK:" "$INSTALL_FLUTTER"
    printf "${YELLOW}%-30s${CYAN}%s${NC}\n" "Flutter Channel:" "$FLUTTER_CHANNEL"
    printf "${YELLOW}%-30s${CYAN}%s${NC}\n" "Flutter Install Dir:" "$FLUTTER_INSTALL_DIR"
    printf "${YELLOW}%-30s${CYAN}%s${NC}\n" "Install Android SDK:" "$INSTALL_ANDROID"
    printf "${YELLOW}%-30s${CYAN}%s${NC}\n" "Android SDK Root:" "$ANDROID_SDK_ROOT"
    printf "${YELLOW}%-30s${CYAN}%s${NC}\n" "Install Visual Studio Code:" "$INSTALL_VSCODE"
    printf "${YELLOW}%-30s${CYAN}%s${NC}\n" "Force Update:" "$FORCE_UPDATE"
    printf "${YELLOW}%-30s${CYAN}%s${NC}\n" "Dry Run:" "$DRY_RUN"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

# **Function to prompt for confirmation**
confirm_settings() {
    display_settings
    read -p "Proceed with these settings? (y/n): " confirm
    case "$confirm" in
        y|Y ) log_info "Proceeding with the setup...";;
        n|N ) log_info "Setup aborted by the user."; exit 0;;
        * ) log_error "Invalid input. Please enter 'y' or 'n'."; confirm_settings;;
    esac
}

# Detect OS and distribution
detect_os() {
    if [ "$(uname)" == "Darwin" ]; then
        OS="macos"
        log_info "Operating System: macOS"
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        OS="linux"
        DISTRO=$ID
        log_info "Operating System: $PRETTY_NAME"
    else
        log_error "Unsupported operating system"
        exit 1
    fi
}

# Determine shell configuration file
get_shell_rc_file() {
    SHELL_NAME=$(basename "$SHELL")
    case "$SHELL_NAME" in
        bash)
            SHELL_RC="$HOME/.bashrc"
            ;;
        zsh)
            SHELL_RC="$HOME/.zshrc"
            ;;
        *)
            log_warn "Unsupported shell ($SHELL_NAME). Defaulting to .bashrc"
            SHELL_RC="$HOME/.bashrc"
            ;;
    esac
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update PATH in shell configuration if not already present
add_to_path() {
    local path_entry="$1"
    if ! grep -Fxq "export PATH=\"\$PATH:$path_entry\"" "$SHELL_RC"; then
        if [ "$DRY_RUN" = false ]; then
            echo "export PATH=\"\$PATH:$path_entry\"" >> "$SHELL_RC"
            source "$SHELL_RC"
        else
            log_info "[Dry Run] Would add $path_entry to PATH in $SHELL_RC"
        fi
    fi
}

# Install dependencies based on OS and distro
install_dependencies() {
    log_info "Installing system dependencies..."
    if [ "$DRY_RUN" = true ]; then
        log_info "[Dry Run] Would install system dependencies"
        return
    fi
    if command_exists sudo; then
        SUDO="sudo"
    else
        SUDO=""
        log_warn "Sudo not found. Proceeding without sudo."
    fi

    if command_exists apt-get; then
        $SUDO apt-get update
        $SUDO apt-get install -y curl git clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev unzip zip xz-utils
    elif command_exists dnf; then
        $SUDO dnf install -y curl git clang cmake ninja-build pkg-config gtk3-devel xz unzip zip
    elif command_exists pacman; then
        $SUDO pacman -Syu --noconfirm curl git clang cmake ninja pkg-config gtk3 xz unzip zip
    elif command_exists zypper; then
        $SUDO zypper install -y curl git clang cmake ninja pkg-config gtk3-devel xz unzip zip
    elif [ "$OS" == "macos" ]; then
        if ! command_exists brew; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew update
        brew install curl git cmake ninja pkg-config unzip zip xz
    else
        log_error "Unsupported package manager"
        exit 1
    fi
}

# Install Flutter SDK
install_flutter() {
    if [ "$INSTALL_FLUTTER" = false ]; then
        log_info "Skipping Flutter installation."
        return
    fi

    log_info "Setting up Flutter SDK..."

    if [ "$DRY_RUN" = true ]; then
        log_info "[Dry Run] Would install Flutter in $FLUTTER_INSTALL_DIR using channel $FLUTTER_CHANNEL"
        return
    fi

    if command_exists flutter; then
        log_info "Flutter is already installed."
        if [ "$FORCE_UPDATE" = true ]; then
            log_info "Updating Flutter..."
            flutter upgrade
        else
            log_info "Skipping Flutter installation."
            return
        fi
    else
        mkdir -p "$FLUTTER_INSTALL_DIR"
        git clone https://github.com/flutter/flutter.git -b "$FLUTTER_CHANNEL" "$FLUTTER_INSTALL_DIR/flutter"

        # Add Flutter to PATH
        add_to_path "$FLUTTER_INSTALL_DIR/flutter/bin"
    fi

    # Enable Flutter
    source "$SHELL_RC"
    flutter config --no-analytics
    flutter precache
    flutter doctor
}

# Setup Android development environment
setup_android() {
    if [ "$INSTALL_ANDROID" = false ]; then
        log_info "Skipping Android SDK installation."
        return
    fi

    log_info "Setting up Android SDK..."

    if [ "$DRY_RUN" = true ]; then
        log_info "[Dry Run] Would install Android SDK in $ANDROID_SDK_ROOT"
        return
    fi

    if command_exists sdkmanager; then
        log_info "Android SDK is already installed."
        if [ "$FORCE_UPDATE" = true ]; then
            log_info "Updating Android SDK components..."
            sdkmanager --update
        else
            log_info "Skipping Android SDK installation."
            return
        fi
    else
        mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
        cd "$ANDROID_SDK_ROOT/cmdline-tools" || exit

        if [ "$OS" == "linux" ]; then
            SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip"
        elif [ "$OS" == "macos" ]; then
            SDK_URL="https://dl.google.com/android/repository/commandlinetools-mac-9477386_latest.zip"
        fi

        curl -o "cmdline-tools.zip" "$SDK_URL"
        unzip "cmdline-tools.zip"
        mv cmdline-tools latest
        rm "cmdline-tools.zip"

        # Add Android SDK to PATH
        if ! grep -Fxq "export ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT" "$SHELL_RC"; then
            if [ "$DRY_RUN" = false ]; then
                echo "export ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT" >> "$SHELL_RC"
            else
                log_info "[Dry Run] Would set ANDROID_SDK_ROOT to $ANDROID_SDK_ROOT in $SHELL_RC"
            fi
        fi
        add_to_path "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"
        add_to_path "$ANDROID_SDK_ROOT/platform-tools"

        # Accept licenses and install required SDK packages
        source "$SHELL_RC"
        yes | sdkmanager --licenses
        sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.2"
    fi
}

# Install Visual Studio Code
install_vscode() {
    if [ "$INSTALL_VSCODE" = false ]; then
        log_info "Skipping Visual Studio Code installation."
        return
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "[Dry Run] Would install Visual Studio Code"
        return
    fi

    if command_exists code; then
        log_info "Visual Studio Code is already installed."
        if [ "$FORCE_UPDATE" = true ]; then
            log_info "Updating Visual Studio Code..."
            if command_exists apt-get; then
                sudo apt-get update && sudo apt-get install --only-upgrade code
            elif command_exists dnf; then
                sudo dnf upgrade -y code
            elif command_exists pacman; then
                sudo pacman -Syu --noconfirm code
            elif command_exists zypper; then
                sudo zypper update -y code
            elif [ "$OS" == "macos" ]; then
                brew upgrade --cask visual-studio-code
            fi
        else
            log_info "Skipping Visual Studio Code installation."
            return
        fi
    else
        log_info "Installing Visual Studio Code..."
        if command_exists apt-get; then
            curl -L "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" -o vscode.deb
            sudo apt install -y ./vscode.deb
            rm vscode.deb
        elif command_exists dnf; then
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
            sudo dnf check-update
            sudo dnf install -y code
        elif command_exists pacman; then
            sudo pacman -Syu --noconfirm code
        elif command_exists zypper; then
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/zypp/repos.d/vscode.repo'
            sudo zypper refresh
            sudo zypper install -y code
        elif [ "$OS" == "macos" ]; then
            brew install --cask visual-studio-code
        else
            log_warn "Automatic installation of VS Code is not supported on this system."
        fi
    fi
}

# Main function
main() {
    log_info "Starting development environment setup..."

    detect_os
    get_shell_rc_file

    confirm_settings

    if [ "$DRY_RUN" = true ]; then
        log_info "[Dry Run] The script is running in dry run mode. No changes will be made."
    fi

    install_dependencies
    install_flutter
    setup_android
    install_vscode

    log_info "Running Flutter doctor..."
    if [ "$DRY_RUN" = false ]; then
        flutter doctor -v
    else
        log_info "[Dry Run] Would run 'flutter doctor -v'"
    fi

    log_info "Setup complete!"
    if [ "$DRY_RUN" = false ]; then
        log_info "Please restart your terminal or source your shell configuration file:"
        echo "source $SHELL_RC"
    else
        log_info "[Dry Run] Dry run completed. No changes were made."
    fi
}

main