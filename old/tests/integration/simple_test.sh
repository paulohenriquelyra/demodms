#!/bin/bash

# Simple integration test
set -e

echo "=== Simple DMS Integration Test ==="

cd "$(dirname "$0")"

# Test each environment
for env in dev staging production; do
    echo "Testing $env environment..."
    
    # Check if tfvars file exists
    if [[ ! -f "${env}.tfvars" ]]; then
        echo "❌ Missing ${env}.tfvars"
        exit 1
    fi
    
    # Initialize if needed
    if [[ ! -d ".terraform" ]]; then
        echo "Initializing Terraform..."
        terraform init -backend=false
    fi
    
    # Validate
    echo "Validating configuration..."
    terraform validate
    
    # Plan
    echo "Running terraform plan for $env..."
    if terraform plan -var-file="${env}.tfvars" -detailed-exitcode > /dev/null 2>&1; then
        echo "✅ $env environment test passed (no changes)"
    else
        exit_code=$?
        if [[ $exit_code -eq 2 ]]; then
            echo "✅ $env environment test passed (changes detected)"
        else
            echo "❌ $env environment test failed (exit code: $exit_code)"
            exit 1
        fi
    fi
done

echo "🎉 All integration tests passed!"