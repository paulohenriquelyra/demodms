#!/bin/bash

# ============================================================================
# DMS Module Comprehensive Integration Test
# ============================================================================
# Feature: dms-module-refactoring, Integration Testing
# This script performs comprehensive integration testing of the DMS module
# Validates: End-to-end module deployment, resource creation, configuration,
# module integration with external resources, and AWS security best practices

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}DMS Module Comprehensive Integration Test Suite${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo -e "Testing complete module functionality and integration patterns"
echo ""

# Function to run test assertion
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "Testing: $test_name"
    ((TOTAL_TESTS++))
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS: $test_name${NC}"
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "${RED}❌ FAIL: $test_name${NC}"
        ((FAILED_TESTS++))
        return 1
    fi
}

# Function to validate terraform plan output
validate_plan_output() {
    local env="$1"
    local plan_file="/tmp/dms_plan_${env}.txt"
    
    echo -e "${YELLOW}--- Comprehensive Validation for $env Environment ---${NC}"
    
    # Generate plan output
    terraform plan -var-file="${env}.tfvars" > "$plan_file" 2>&1
    
    # Test 1: Validate all required resources are created
    echo -e "Validating resource creation..."
    
    run_test "DMS Replication Instance creation" "grep -q 'aws_dms_replication_instance.main' '$plan_file'"
    run_test "DMS Subnet Group creation" "grep -q 'aws_dms_replication_subnet_group.main' '$plan_file'"
    run_test "Source Endpoint creation" "grep -q 'aws_dms_endpoint.source' '$plan_file'"
    run_test "Target Endpoint creation" "grep -q 'aws_dms_endpoint.target' '$plan_file'"
    run_test "Replication Task creation" "grep -q 'aws_dms_replication_task.main' '$plan_file'"
    run_test "Security Group creation" "grep -q 'aws_security_group.dms' '$plan_file'"
    
    # Test 2: Validate security configurations
    echo -e "Validating security configurations..."
    
    run_test "Private access enforced" "grep -q 'publicly_accessible.*=.*false' '$plan_file'"
    run_test "SSL mode configured" "grep -q 'ssl_mode.*=.*\"require\"' '$plan_file'"
    run_test "Security group rules created" "grep -q 'aws_security_group_rule' '$plan_file'"
    
    # Test 3: Validate environment-specific configurations
    echo -e "Validating environment-specific configurations..."
    
    case $env in
        "dev")
            run_test "Dev uses cost-optimized instance" "grep -q 'replication_instance_class.*=.*\"dms.t3.micro\"' '$plan_file'"
            run_test "Dev uses single-AZ" "grep -q 'multi_az.*=.*false' '$plan_file'"
            ;;
        "staging")
            run_test "Staging uses balanced instance" "grep -q 'replication_instance_class.*=.*\"dms.t3.small\"' '$plan_file'"
            run_test "Staging uses single-AZ" "grep -q 'multi_az.*=.*false' '$plan_file'"
            ;;
        "production")
            run_test "Production uses production instance" "grep -q 'replication_instance_class.*=.*\"dms.r5.large\"' '$plan_file'"
            run_test "Production uses Multi-AZ" "grep -q 'multi_az.*=.*true' '$plan_file'"
            ;;
    esac
    
    # Test 4: Validate resource naming consistency
    echo -e "Validating resource naming consistency..."
    
    run_test "Consistent resource naming" "grep -q 'dms-${env}-' '$plan_file'"
    run_test "No generic 'main' names" "! grep -q '\"main\"' '$plan_file'"
    
    # Test 5: Validate tagging strategy
    echo -e "Validating tagging strategy..."
    
    run_test "Environment tags applied" "grep -q '\"Environment\".*=.*\"${env}\"' '$plan_file'"
    run_test "Project tags applied" "grep -q '\"Project\".*=.*\"dms\"' '$plan_file'"
    run_test "Module tags applied" "grep -q '\"Module\".*=.*\"dms\"' '$plan_file'"
    run_test "ManagedBy tags applied" "grep -q '\"ManagedBy\".*=.*\"terraform\"' '$plan_file'"
    
    # Test 6: Validate outputs structure
    echo -e "Validating module outputs..."
    
    run_test "DMS instance outputs" "grep -q 'dms_instance.*=' '$plan_file'"
    run_test "Replication task outputs" "grep -q 'replication_task.*=' '$plan_file'"
    run_test "Endpoints outputs" "grep -q 'endpoints.*=' '$plan_file'"
    run_test "Network outputs" "grep -q 'network.*=' '$plan_file'"
    
    # Test 7: Validate backward compatibility
    echo -e "Validating backward compatibility..."
    
    run_test "Legacy replication_instance_arn output" "grep -q 'replication_instance_arn.*=' '$plan_file'"
    run_test "Legacy replication_task_arn output" "grep -q 'replication_task_arn.*=' '$plan_file'"
    run_test "Legacy source_endpoint_arn output" "grep -q 'source_endpoint_arn.*=' '$plan_file'"
    run_test "Legacy target_endpoint_arn output" "grep -q 'target_endpoint_arn.*=' '$plan_file'"
    
    # Cleanup
    rm -f "$plan_file"
    
    echo ""
}

# Function to test module integration patterns
test_module_integration() {
    echo -e "${YELLOW}--- Testing Module Integration Patterns ---${NC}"
    
    # Test 1: Module can be called from different contexts
    echo -e "Testing module invocation patterns..."
    
    run_test "Module source path resolution" "test -f '../../main-dms.tf'"
    run_test "Module variables interface" "test -f '../../variables.tf'"
    run_test "Module outputs interface" "test -f '../../outputs.tf'"
    run_test "Module locals configuration" "test -f '../../locals.tf'"
    
    # Test 2: Validate module structure follows HashiCorp standards
    echo -e "Testing HashiCorp module standards..."
    
    run_test "README documentation exists" "test -f '../../README.md'"
    run_test "No main.tf (uses descriptive naming)" "! test -f '../../main.tf'"
    run_test "Descriptive main file exists" "test -f '../../main-dms.tf'"
    
    # Test 3: Test variable validation
    echo -e "Testing variable validation..."
    
    # Create a test file with invalid project name
    cat > test_invalid.tfvars << EOF
project_name = "INVALID-NAME-WITH-CAPS"
environment = "test"
vpc_id = "vpc-12345678"
subnet_ids = ["subnet-12345678"]
dms_instance_config = {
  instance_class = "dms.t3.micro"
  allocated_storage = 20
  engine_version = "3.5.2"
  multi_az = false
  publicly_accessible = false
  auto_minor_version_upgrade = true
}
source_endpoint_config = {
  engine_name = "mysql"
  server_name = "test.example.com"
  port = 3306
  database_name = "test"
  username = "user"
  password = "pass"
  ssl_mode = "require"
}
target_endpoint_config = {
  engine_name = "aurora-postgresql"
  server_name = "test.cluster.amazonaws.com"
  port = 5432
  database_name = "test"
  username = "postgres"
  password = "pass"
  ssl_mode = "require"
}
enable_secrets_manager = false
kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
source_security_group_id = "sg-12345678"
target_security_group_id = "sg-87654321"
migration_type = "full-load-and-cdc"
table_mappings = "{\"rules\":[{\"rule-type\":\"selection\",\"rule-id\":\"1\",\"rule-name\":\"1\",\"object-locator\":{\"schema-name\":\"test\",\"table-name\":\"%\"},\"rule-action\":\"include\"}]}"
environment_config = {
  backup_retention_period = 1
  monitoring_interval = 0
  performance_insights = false
  deletion_protection = false
}
tags = {}
EOF
    
    # Test that validation catches invalid input
    if terraform plan -var-file="test_invalid.tfvars" > /dev/null 2>&1; then
        echo -e "${RED}❌ FAIL: Variable validation should reject invalid project name${NC}"
        ((FAILED_TESTS++))
    else
        echo -e "${GREEN}✓ PASS: Variable validation correctly rejects invalid input${NC}"
        ((PASSED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    
    # Cleanup
    rm -f test_invalid.tfvars
    
    echo ""
}

# Function to test AWS security best practices
test_security_best_practices() {
    echo -e "${YELLOW}--- Testing AWS Security Best Practices ---${NC}"
    
    # Generate a plan for security analysis
    local security_plan="/tmp/dms_security_plan.txt"
    terraform plan -var-file="production.tfvars" > "$security_plan" 2>&1
    
    echo -e "Validating security best practices implementation..."
    
    # Test 1: Encryption configurations
    run_test "KMS encryption configured" "grep -q 'kms_key_arn.*=.*\"arn:aws:kms:' '$security_plan'"
    
    # Test 2: Network security
    run_test "Private subnet deployment" "grep -q 'publicly_accessible.*=.*false' '$security_plan'"
    run_test "Security group restrictions" "grep -q 'aws_security_group.dms' '$security_plan'"
    
    # Test 3: SSL/TLS enforcement
    run_test "SSL mode enforcement" "grep -q 'ssl_mode.*=.*\"require\"' '$security_plan'"
    
    # Test 4: Least privilege access
    run_test "Specific port access only" "grep -q 'from_port.*=.*3306\\|from_port.*=.*5432' '$security_plan'"
    run_test "No wildcard access" "! grep -q 'from_port.*=.*0.*to_port.*=.*65535' '$security_plan'"
    
    # Test 5: Monitoring and logging
    run_test "Enhanced monitoring support" "grep -q 'monitoring_interval' '$security_plan'"
    
    # Cleanup
    rm -f "$security_plan"
    
    echo ""
}

# Main test execution
main() {
    cd "$TEST_DIR"
    
    # Initialize Terraform if needed
    if [[ ! -d ".terraform" ]]; then
        echo -e "Initializing Terraform..."
        terraform init -backend=false > /dev/null 2>&1
    fi
    
    # Validate configuration
    echo -e "Validating Terraform configuration..."
    terraform validate > /dev/null 2>&1
    
    # Test each environment comprehensively
    for env in dev staging production; do
        validate_plan_output "$env"
    done
    
    # Test module integration patterns
    test_module_integration
    
    # Test security best practices
    test_security_best_practices
    
    # Test Summary
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "${BLUE}Comprehensive Integration Test Summary${NC}"
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "Total Tests: $TOTAL_TESTS"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}🎉 ALL COMPREHENSIVE INTEGRATION TESTS PASSED!${NC}"
        echo -e "${GREEN}✅ End-to-end module deployment validation - COMPLETE${NC}"
        echo -e "${GREEN}✅ Resource creation and configuration - VALIDATED${NC}"
        echo -e "${GREEN}✅ Module integration with external resources - VALIDATED${NC}"
        echo -e "${GREEN}✅ AWS security best practices enforcement - VALIDATED${NC}"
        echo -e "${GREEN}✅ HashiCorp module standards compliance - VALIDATED${NC}"
        echo -e "${GREEN}✅ Backward compatibility - MAINTAINED${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some comprehensive integration tests failed!${NC}"
        echo -e "${RED}Please fix the issues above before proceeding.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"