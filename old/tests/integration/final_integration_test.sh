#!/bin/bash

# ============================================================================
# DMS Module Final Integration Test
# ============================================================================
# Comprehensive validation of the DMS module functionality

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}DMS Module Final Integration Test${NC}"
echo -e "${BLUE}============================================================================${NC}"

cd "$(dirname "$0")"

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

test_result() {
    local test_name="$1"
    local result="$2"
    
    ((TOTAL_TESTS++))
    
    if [[ "$result" == "PASS" ]]; then
        echo -e "${GREEN}✓ PASS: $test_name${NC}"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}❌ FAIL: $test_name${NC}"
        ((FAILED_TESTS++))
    fi
}

# Initialize if needed
if [[ ! -d ".terraform" ]]; then
    echo "Initializing Terraform..."
    terraform init -backend=false > /dev/null 2>&1
fi

echo "Validating Terraform configuration..."
if terraform validate > /dev/null 2>&1; then
    test_result "Terraform configuration validation" "PASS"
else
    test_result "Terraform configuration validation" "FAIL"
fi

# Test each environment
for env in dev staging production; do
    echo -e "\n${YELLOW}--- Testing $env Environment ---${NC}"
    
    # Test terraform plan
    if terraform plan -var-file="${env}.tfvars" > /tmp/plan_${env}.txt 2>&1; then
        test_result "$env environment plan generation" "PASS"
        
        # Check for key resources
        if grep -q "aws_dms_replication_instance" /tmp/plan_${env}.txt; then
            test_result "$env DMS instance resource" "PASS"
        else
            test_result "$env DMS instance resource" "FAIL"
        fi
        
        if grep -q "aws_dms_endpoint" /tmp/plan_${env}.txt; then
            test_result "$env DMS endpoints resources" "PASS"
        else
            test_result "$env DMS endpoints resources" "FAIL"
        fi
        
        if grep -q "aws_dms_replication_task" /tmp/plan_${env}.txt; then
            test_result "$env DMS replication task" "PASS"
        else
            test_result "$env DMS replication task" "FAIL"
        fi
        
        if grep -q "aws_security_group" /tmp/plan_${env}.txt; then
            test_result "$env Security group" "PASS"
        else
            test_result "$env Security group" "FAIL"
        fi
        
        # Check environment-specific configurations
        case $env in
            "dev")
                if grep -q "dms.t3.micro" /tmp/plan_${env}.txt; then
                    test_result "$env cost-optimized instance class" "PASS"
                else
                    test_result "$env cost-optimized instance class" "FAIL"
                fi
                ;;
            "staging")
                if grep -q "dms.t3.small" /tmp/plan_${env}.txt; then
                    test_result "$env balanced instance class" "PASS"
                else
                    test_result "$env balanced instance class" "FAIL"
                fi
                ;;
            "production")
                if grep -q "dms.r5.large" /tmp/plan_${env}.txt; then
                    test_result "$env production instance class" "PASS"
                else
                    test_result "$env production instance class" "FAIL"
                fi
                
                if grep -q "multi_az.*=.*true" /tmp/plan_${env}.txt; then
                    test_result "$env Multi-AZ configuration" "PASS"
                else
                    test_result "$env Multi-AZ configuration" "FAIL"
                fi
                ;;
        esac
        
        # Check security configurations
        if grep -q "publicly_accessible.*=.*false" /tmp/plan_${env}.txt; then
            test_result "$env private access enforcement" "PASS"
        else
            test_result "$env private access enforcement" "FAIL"
        fi
        
        if grep -q "ssl_mode.*=.*\"require\"" /tmp/plan_${env}.txt; then
            test_result "$env SSL enforcement" "PASS"
        else
            test_result "$env SSL enforcement" "FAIL"
        fi
        
        # Check naming consistency
        if grep -q "dms-${env}-" /tmp/plan_${env}.txt; then
            test_result "$env resource naming consistency" "PASS"
        else
            test_result "$env resource naming consistency" "FAIL"
        fi
        
        # Check tagging
        if grep -q "\"Environment\".*=.*\"${env}\"" /tmp/plan_${env}.txt; then
            test_result "$env environment tagging" "PASS"
        else
            test_result "$env environment tagging" "FAIL"
        fi
        
    else
        test_result "$env environment plan generation" "FAIL"
    fi
done

# Test module structure
echo -e "\n${YELLOW}--- Testing Module Structure ---${NC}"

if [[ -f "../../main-dms.tf" ]]; then
    test_result "Descriptive main file exists" "PASS"
else
    test_result "Descriptive main file exists" "FAIL"
fi

if [[ ! -f "../../main.tf" ]]; then
    test_result "Generic main.tf not present" "PASS"
else
    test_result "Generic main.tf not present" "FAIL"
fi

if [[ -f "../../variables.tf" ]]; then
    test_result "Variables file exists" "PASS"
else
    test_result "Variables file exists" "FAIL"
fi

if [[ -f "../../outputs.tf" ]]; then
    test_result "Outputs file exists" "PASS"
else
    test_result "Outputs file exists" "FAIL"
fi

if [[ -f "../../locals.tf" ]]; then
    test_result "Locals file exists" "PASS"
else
    test_result "Locals file exists" "FAIL"
fi

if [[ -f "../../README.md" ]]; then
    test_result "README documentation exists" "PASS"
else
    test_result "README documentation exists" "FAIL"
fi

# Test variable validation
echo -e "\n${YELLOW}--- Testing Variable Validation ---${NC}"

# Create invalid configuration
cat > test_invalid.tfvars << 'EOF'
project_name = "INVALID-NAME"
environment = "test"
vpc_id = "invalid-vpc"
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

if terraform plan -var-file="test_invalid.tfvars" > /dev/null 2>&1; then
    test_result "Variable validation (should reject invalid input)" "FAIL"
else
    test_result "Variable validation (should reject invalid input)" "PASS"
fi

# Cleanup
rm -f test_invalid.tfvars
rm -f /tmp/plan_*.txt

# Summary
echo -e "\n${BLUE}============================================================================${NC}"
echo -e "${BLUE}Final Integration Test Summary${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo -e "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${RED}Failed: $FAILED_TESTS${NC}"

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 ALL INTEGRATION TESTS PASSED!${NC}"
    echo -e "${GREEN}✅ Multi-environment deployment - VALIDATED${NC}"
    echo -e "${GREEN}✅ Resource creation and configuration - VALIDATED${NC}"
    echo -e "${GREEN}✅ Security best practices - VALIDATED${NC}"
    echo -e "${GREEN}✅ Module structure and standards - VALIDATED${NC}"
    echo -e "${GREEN}✅ Variable validation - VALIDATED${NC}"
    echo -e "${GREEN}✅ Integration testing complete - SUCCESS${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some integration tests failed!${NC}"
    echo -e "${RED}Please review and fix the issues above.${NC}"
    exit 1
fi