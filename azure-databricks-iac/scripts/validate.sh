#!/bin/bash
# Validation script for Bicep templates

set -e

echo "🔍 Validating Bicep templates..."

# Build all modules
echo "📦 Building Bicep modules..."
bicep build bicep/modules/networking.bicep
bicep build bicep/modules/storage.bicep
bicep build bicep/modules/databricks.bicep
bicep build bicep/modules/monitoring.bicep

# Build main template
echo "📦 Building main template..."
bicep build bicep/main.bicep

# Validate against Azure (if logged in)
if az account show &> /dev/null; then
    echo "✅ Validating against Azure..."
    az deployment sub validate \
        --location eastus \
        --template-file bicep/main.bicep \
        --parameters bicep/parameters/parameters.dev.json
    echo "✅ Validation successful!"
else
    echo "⚠️ Not logged into Azure. Skipping Azure validation."
    echo "   Run 'az login' to enable full validation."
fi

echo "✅ All validations passed!"
