#!/bin/bash

# ============================================================================
# DMS Module Integration Test Runner
# ============================================================================
# Feature: dms-module-refactoring, Property 4: Multi-Environment Deployment Consistency
# This script tests the DMS module with different environment configurations
# Validates: Requirements 7.1, 7.2, 7.3, 7.4, 11.1, 11.2, 11.3, 11.4, 13.1, 13.2, 13.3, 13.4, 13.5

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
ENVIRONMENTS=("dev" "staging" "production")
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}DMS Module Integration Test Suite${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo -e "Testing module at: ${TEST_DIR}/../.."
echo -e "Running integration tests for environments: ${ENVIRONMENTS[*]}"
echo ""

# Function to run test for a specific environment
run_environment_test() {
    local env=$1
    local tfvars_file="${TEST_DIR}/${env}.tfvars"
    
    echo -e "${YELLOW}--- Testing Environment: ${env} ---${NC}"
    
    if [[ ! -f "$tfvars_file" ]]; then
        echo -e "${RED}❌ FAIL: Configuration file not found: $tfvars_file${NC}"
        ((FAILED_TESTS++))
        return 1
    fi
    
    echo -e "✓ Found configuration file: $tfvars_file"
    ((TOTAL_TESTS++))
    
    # Initialize Terraform
    echo -e "Initializing Terraform..."
    local init_output
    if init_output=$(terraform init -backend=false 2>&1); then
        echo -e "${GREEN}✓ Terraform initialization successful${NC}"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}❌ FAIL: Terraform initialization failed${NC}"
        echo "$init_output"
        ((FAILED_TESTS++))
        return 1
    fi
    ((TOTAL_TESTS++))
    
    # Validate Terraform configuration
    echo -e "Validating Terraform configuration..."
    if terraform validate > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Terraform validation successful${NC}"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}❌ FAIL: Terraform validation failed${NC}"
        terraform validate
        ((FAILED_TESTS++))
        return 1
    fi
    ((TOTAL_TESTS++))
    
    # Run terraform plan
    echo -e "Running terraform plan for ${env} environment..."
    local plan_output
    if plan_output=$(terraform plan -var-file="$tfvars_file" -detailed-exitcode 2>&1); then
        local exit_code=$?
        if [[ $exit_code -eq 0 || $exit_code -eq 2 ]]; then
            echo -e "${GREEN}✓ Terraform plan successful for ${env}${NC}"
            ((PASSED_TESTS++))
            
            # Validate specific configurations based on environment
            validate_environment_specific_config "$env" "$plan_output"
        else
            echo -e "${RED}❌ FAIL: Terraform plan failed for ${env}${NC}"
            echo "$plan_output"
            ((FAILED_TESTS++))
            return 1
        fi
    else
        echo -e "${RED}❌ FAIL: Terraform plan failed for ${env}${NC}"
        echo "$plan_output"
        ((FAILED_TESTS++))
        return 1
    fi
    ((TOTAL_TESTS++))
    
    echo -e "${GREEN}✓ Environment ${env} tests completed successfully${NC}"
    echo ""
}

# Function to validate environment-specific configurations
validate_environment_specific_config() {
    local env=$1
    local plan_output="$2"
    
    echo -e "Validating environment-specific configurations for ${env}..."
    
    # Test 1: Validate instance class based on environment
    case $env in
        "dev")
            if echo "$plan_output" | grep -q "instance_class.*=.*\"dms.t3.micro\""; then
                echo -e "${GREEN}✓ Dev environment uses cost-optimized instance class${NC}"
                ((PASSED_TESTS++))
            else
                echo -e "${RED}❌ FAIL: Dev environment should use dms.t3.micro${NC}"
                ((FAILED_TESTS++))
            fi
            ;;
        "staging")
            if echo "$plan_output" | grep -q "instance_class.*=.*\"dms.t3.small\""; then
                echo -e "${GREEN}✓ Staging environment uses balanced instance class${NC}"
                ((PASSED_TESTS++))
            else
                echo -e "${RED}❌ FAIL: Staging environment should use dms.t3.small${NC}"
                ((FAILED_TESTS++))
            fi
            ;;
        "production")
            if echo "$plan_output" | grep -q "instance_class.*=.*\"dms.r5.large\""; then
                echo -e "${GREEN}✓ Production environment uses production-grade instance class${NC}"
                ((PASSED_TESTS++))
            else
                echo -e "${RED}❌ FAIL: Production environment should use dms.r5.large${NC}"
                ((FAILED_TESTS++))
            fi
            ;;
    esac
    ((TOTAL_TESTS++))
    
    # Test 2: Validate Multi-AZ configuration
    case $env in
        "dev"|"staging")
            if echo "$plan_output" | grep -q "multi_az.*=.*false"; then
                echo -e "${GREEN}✓ ${env} environment uses single-AZ for cost optimization${NC}"
                ((PASSED_TESTS++))
            else
                echo -e "${RED}❌ FAIL: ${env} environment should use single-AZ${NC}"
                ((FAILED_TESTS++))
            fi
            ;;
        "production")
            if echo "$plan_output" | grep -q "multi_az.*=.*true"; then
                echo -e "${GREEN}✓ Production environment uses Multi-AZ for high availability${NC}"
                ((PASSED_TESTS++))
            else
                echo -e "${RED}❌ FAIL: Production environment should use Multi-AZ${NC}"
                ((FAILED_TESTS++))
            fi
            ;;
    esac
    ((TOTAL_TESTS++))
    
    # Test 3: Validate Secrets Manager configuration
    case $env in
        "dev")
            if echo "$plan_output" | grep -q "enable_secrets_manager.*=.*false"; then
                echo -e "${GREEN}✓ Dev environment uses direct credentials for simplicity${NC}"
                ((PASSED_TESTS++))
            else
                echo -e "${RED}❌ FAIL: Dev environment should use direct credentials${NC}"
                ((FAILED_TESTS++))
            fi
            ;;
        "staging"|"production")
            if echo "$plan_output" | grep -q "enable_secrets_manager.*=.*true"; then
                echo -e "${GREEN}✓ ${env} environment uses Secrets Manager for security${NC}"
                ((PASSED_TESTS++))
            else
                echo -e "${RED}❌ FAIL: ${env} environment should use Secrets Manager${NC}"
                ((FAILED_TESTS++))
            fi
            ;;
    esac
    ((TOTAL_TESTS++))
    
    # Test 4: Validate resource naming patterns
    if echo "$plan_output" | grep -q "test-dms-${env}"; then
        echo -e "${GREEN}✓ Resource naming follows environment-specific pattern${NC}"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}❌ FAIL: Resource naming should include environment: test-dms-${env}${NC}"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    
    # Test 5: Validate security configurations
    if echo "$plan_output" | grep -q "publicly_accessible.*=.*false"; then
        echo -e "${GREEN}✓ Security: Resources are not publicly accessible${NC}"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}❌ FAIL: Security: Resources should not be publicly accessible${NC}"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
}

# Function to test Secrets Manager scenarios
test_secrets_manager_scenarios() {
    echo -e "${YELLOW}--- Testing Secrets Manager Scenarios ---${NC}"
    
    # Test with Secrets Manager enabled (staging config)
    echo -e "Testing Secrets Manager enabled scenario..."
    if terraform plan -var-file="staging.tfvars" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Secrets Manager enabled scenario works${NC}"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}❌ FAIL: Secrets Manager enabled scenario failed${NC}"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    
    # Test with Secrets Manager disabled (dev config)
    echo -e "Testing Secrets Manager disabled scenario..."
    if terraform plan -var-file="dev.tfvars" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Secrets Manager disabled scenario works${NC}"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}❌ FAIL: Secrets Manager disabled scenario failed${NC}"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
}

# Function to test Multi-AZ scenarios
test_multi_az_scenarios() {
    echo -e "${YELLOW}--- Testing Multi-AZ Scenarios ---${NC}"
    
    # Test Single-AZ (dev/staging)
    echo -e "Testing Single-AZ configuration..."
    if terraform plan -var-file="dev.tfvars" | grep -q "multi_az.*=.*false"; then
        echo -e "${GREEN}✓ Single-AZ configuration works${NC}"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}❌ FAIL: Single-AZ configuration failed${NC}"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    
    # Test Multi-AZ (production)
    echo -e "Testing Multi-AZ configuration..."
    if terraform plan -var-file="production.tfvars" | grep -q "multi_az.*=.*true"; then
        echo -e "${GREEN}✓ Multi-AZ configuration works${NC}"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}❌ FAIL: Multi-AZ configuration failed${NC}"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
}

# Main test execution
main() {
    cd "$TEST_DIR"
    
    # Test each environment
    for env in "${ENVIRONMENTS[@]}"; do
        run_environment_test "$env"
    done
    
    # Test specific scenarios
    test_secrets_manager_scenarios
    test_multi_az_scenarios
    
    # Test Summary
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "${BLUE}Integration Test Summary${NC}"
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "Total Tests: $TOTAL_TESTS"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}🎉 ALL INTEGRATION TESTS PASSED!${NC}"
        echo -e "${GREEN}✅ Property 4: Multi-Environment Deployment Consistency - VALIDATED${NC}"
        echo -e "${GREEN}✅ Requirements 7.1, 7.2, 7.3, 7.4 - VALIDATED${NC}"
        echo -e "${GREEN}✅ Requirements 11.1, 11.2, 11.3, 11.4 - VALIDATED${NC}"
        echo -e "${GREEN}✅ Requirements 13.1, 13.2, 13.3, 13.4, 13.5 - VALIDATED${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some integration tests failed!${NC}"
        echo -e "${RED}Please fix the issues above before proceeding.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"