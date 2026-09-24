#!/bin/bash
# Setup script for Bicep development environment

set -e

echo "🚀 Setting up Bicep development environment..."

# Check if running on Linux or macOS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

echo "📍 Detected OS: $MACHINE"

# Install Bicep CLI
install_bicep() {
    if command -v bicep &> /dev/null; then
        echo "✅ Bicep is already installed"
        bicep --version
        return
    fi
    
    echo "📦 Installing Bicep CLI..."
    
    if [ "$MACHINE" == "Linux" ]; then
        curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
        chmod +x ./bicep
        sudo mv ./bicep /usr/local/bin/bicep
    elif [ "$MACHINE" == "Mac" ]; then
        brew install bicep
    fi
    
    bicep --version
    echo "✅ Bicep CLI installed successfully"
}

# Install Azure CLI
install_azure_cli() {
    if command -v az &> /dev/null; then
        echo "✅ Azure CLI is already installed"
        az --version | head -n 1
        return
    fi
    
    echo "📦 Installing Azure CLI..."
    
    if [ "$MACHINE" == "Linux" ]; then
        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    elif [ "$MACHINE" == "Mac" ]; then
        brew install azure-cli
    fi
    
    echo "✅ Azure CLI installed successfully"
}

# Install Bicep extension for Azure CLI
install_bicep_extension() {
    echo "📦 Installing Bicep extension for Azure CLI..."
    az extension add --name bicep --yes
    az bicep install
    az bicep version
    echo "✅ Bicep extension installed"
}

# Install PSRule for security scanning
install_psrule() {
    echo "📦 Installing PSRule for Azure..."
    
    if command -v pwsh &> /dev/null; then
        pwsh -Command "Install-Module -Name PSRule.Rules.Azure -Scope CurrentUser -Force"
        echo "✅ PSRule installed successfully"
    else
        echo "⚠️ PowerShell Core not found. Skipping PSRule installation."
        echo "   Install PowerShell Core to enable security scanning."
    fi
}

# Main installation flow
main() {
    install_bicep
    install_azure_cli
    install_bicep_extension
    install_psrule
    
    echo ""
    echo "✅ Setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Run 'az login' to authenticate with Azure"
    echo "2. Set your subscription: az account set --subscription <subscription-id>"
    echo "3. Update bicep/parameters/parameters.dev.json with your values"
    echo "4. Run 'bicep build bicep/main.bicep' to validate"
}

main
