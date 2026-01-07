# ============================================================================
# Resource Naming Consistency Validation Script
# ============================================================================
#
# Feature: dms-module-refactoring, Property 1: Resource Naming Consistency
# Property: For any module configuration with project name and environment, 
# all generated resource names should follow the consistent pattern 
# "{project_name}-{environment}-{component}-{resource_type}" and never use generic "main" names.
# Validates: Requirements 2.1, 2.2, 2.3, 2.4
#
# This script validates that:
# 1. All resource names follow the centralized naming pattern
# 2. No generic "main" names are used
# 3. Naming patterns are consistent across all resource types
# 4. Descriptive prefixes indicate resource purpose
# ============================================================================

param(
    [string]$ModulePath = "../",
    [string[]]$TestProjects = @("test-dms", "prod-migration", "dev-analytics"),
    [string[]]$TestEnvironments = @("dev", "staging", "production")
)

Write-Host "=== Resource Naming Consistency Validation ===" -ForegroundColor Green
Write-Host "Module Path: $ModulePath" -ForegroundColor Yellow

$ErrorCount = 0
$TestCount = 0

function Test-Assertion {
    param(
        [bool]$Condition,
        [string]$TestName,
        [string]$ErrorMessage
    )
    
    $script:TestCount++
    
    if ($Condition) {
        Write-Host "✅ PASS: $TestName" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ FAIL: $TestName - $ErrorMessage" -ForegroundColor Red
        $script:ErrorCount++
        return $false
    }
}

# Test 1: Validate locals.tf naming configuration
Write-Host "`n--- Test 1: Naming Configuration Structure ---" -ForegroundColor Cyan

$localsFile = Join-Path $ModulePath "locals.tf"
$localsExists = Test-Path $localsFile
Test-Assertion $localsExists "Locals file exists" "locals.tf file not found"

if ($localsExists) {
    $localsContent = Get-Content $localsFile -Raw
    
    # Check for centralized naming configuration
    $namingBlock = $localsContent -match "naming\s*=\s*\{"
    Test-Assertion $namingBlock "Naming block exists in locals" "Centralized naming configuration not found"
    
    # Check for prefix pattern
    $prefixPattern = $localsContent -match 'prefix\s*=\s*"\$\{var\.project_name\}-\$\{var\.environment\}"'
    Test-Assertion $prefixPattern "Naming prefix follows pattern" "Prefix should follow {project_name}-{environment} pattern"
    
    # Check for resource_names block
    $resourceNamesBlock = $localsContent -match "resource_names\s*=\s*\{"
    Test-Assertion $resourceNamesBlock "Resource names block exists" "Centralized resource names configuration not found"
    
    # Check for all required resource name definitions
    $requiredResourceNames = @(
        "dms_instance",
        "subnet_group", 
        "security_group",
        "source_endpoint",
        "target_endpoint",
        "replication_task"
    )
    
    foreach ($resourceName in $requiredResourceNames) {
        $resourceExists = $localsContent -match "$resourceName\s*="
        Test-Assertion $resourceExists "Resource name '$resourceName' defined" "Resource name '$resourceName' not found in locals"
    }
}

# Test 2: Validate main-dms.tf uses centralized naming
Write-Host "`n--- Test 2: Main File Naming Usage ---" -ForegroundColor Cyan

$mainFile = Join-Path $ModulePath "main-dms.tf"
$mainExists = Test-Path $mainFile
Test-Assertion $mainExists "Main DMS file exists" "main-dms.tf file not found"

if ($mainExists) {
    $mainContent = Get-Content $mainFile -Raw
    
    # Check that all resources use local.resource_names references
    $namingReferences = @(
        @{Pattern = "local\.resource_names\.dms_instance"; Resource = "DMS Instance"},
        @{Pattern = "local\.resource_names\.subnet_group"; Resource = "Subnet Group"},
        @{Pattern = "local\.resource_names\.security_group"; Resource = "Security Group"},
        @{Pattern = "local\.resource_names\.source_endpoint"; Resource = "Source Endpoint"},
        @{Pattern = "local\.resource_names\.target_endpoint"; Resource = "Target Endpoint"},
        @{Pattern = "local\.resource_names\.replication_task"; Resource = "Replication Task"}
    )
    
    foreach ($ref in $namingReferences) {
        $patternFound = $mainContent -match $ref.Pattern
        Test-Assertion $patternFound "$($ref.Resource) uses centralized naming" "$($ref.Resource) should use $($ref.Pattern)"
    }
    
    # Check that no hardcoded project_name references exist
    $hardcodedPatterns = @(
        'replication_instance_id\s*=\s*"\$\{var\.project_name\}',
        'replication_subnet_group_id\s*=\s*"\$\{var\.project_name\}',
        'endpoint_id\s*=\s*"\$\{var\.project_name\}',
        'replication_task_id\s*=\s*"\$\{var\.project_name\}'
    )
    
    foreach ($pattern in $hardcodedPatterns) {
        $patternFound = $mainContent -match $pattern
        Test-Assertion (-not $patternFound) "No hardcoded naming: $pattern" "Should use centralized naming instead of direct variable interpolation"
    }
    
    # Check that no generic "main" names are used
    $genericPatterns = @(
        'replication_instance_id\s*=\s*".*-main"',
        'replication_subnet_group_id\s*=\s*".*-main"',
        'endpoint_id\s*=\s*".*-main"',
        'replication_task_id\s*=\s*".*-main"'
    )
    
    foreach ($pattern in $genericPatterns) {
        $patternFound = $mainContent -match $pattern
        Test-Assertion (-not $patternFound) "No generic 'main' names: $pattern" "Should use descriptive names instead of generic 'main'"
    }
}

# Test 3: Validate naming pattern consistency across different configurations
Write-Host "`n--- Test 3: Naming Pattern Consistency ---" -ForegroundColor Cyan

if ($localsExists) {
    $localsContent = Get-Content $localsFile -Raw
    
    # Check that resource names use the centralized prefix pattern
    $prefixUsagePatterns = @(
        "dms_instance.*local\.naming\.prefix",
        "subnet_group.*local\.naming\.prefix", 
        "security_group.*local\.naming\.prefix",
        "source_endpoint.*local\.naming\.prefix",
        "target_endpoint.*local\.naming\.prefix",
        "replication_task.*local\.naming\.prefix"
    )
    
    foreach ($pattern in $prefixUsagePatterns) {
        $patternFound = $localsContent -match $pattern
        $resourceName = $pattern -split '\.' | Select-Object -First 1
        Test-Assertion $patternFound "Resource '$resourceName' uses centralized prefix" "Resource '$resourceName' should use local.naming.prefix"
    }
}

# Test 4: Validate descriptive naming conventions
Write-Host "`n--- Test 4: Descriptive Naming Conventions ---" -ForegroundColor Cyan

if ($localsExists) {
    $localsContent = Get-Content $localsFile -Raw
    
    # Check for descriptive component identifiers
    $descriptivePatterns = @(
        @{Pattern = "dms-instance"; Description = "DMS Instance uses descriptive identifier"},
        @{Pattern = "dms-subnet-group"; Description = "Subnet Group uses descriptive identifier"},
        @{Pattern = "dms-sg"; Description = "Security Group uses descriptive identifier"},
        @{Pattern = "source-"; Description = "Source endpoint uses descriptive prefix"},
        @{Pattern = "target-"; Description = "Target endpoint uses descriptive prefix"},
        @{Pattern = "replication-task"; Description = "Replication task uses descriptive identifier"}
    )
    
    foreach ($pattern in $descriptivePatterns) {
        $patternFound = $localsContent -match $pattern.Pattern
        Test-Assertion $patternFound $pattern.Description "Should use descriptive naming: $($pattern.Pattern)"
    }
}

# Test 5: Validate descriptive naming patterns
Write-Host "`n--- Test 5: Descriptive Naming Patterns ---" -ForegroundColor Cyan

if ($localsExists) {
    $localsContent = Get-Content $localsFile -Raw
    
    # Check that all expected descriptive patterns exist in the file
    $descriptivePatterns = @(
        "dms-instance",
        "dms-subnet-group", 
        "dms-sg",
        "source-",
        "target-",
        "replication-task"
    )
    
    foreach ($pattern in $descriptivePatterns) {
        $patternFound = $localsContent -match $pattern
        Test-Assertion $patternFound "Descriptive pattern '$pattern' used" "Should use descriptive pattern: $pattern"
    }
    
    # Check that resource_names block exists and has content
    $resourceNamesExists = $localsContent -match "resource_names\s*=\s*\{"
    Test-Assertion $resourceNamesExists "Resource names block properly defined" "Resource names block should be properly structured"
}

# Test 6: Validate file naming convention (main-dms.tf)
Write-Host "`n--- Test 6: File Naming Convention ---" -ForegroundColor Cyan

$mainDmsExists = Test-Path (Join-Path $ModulePath "main-dms.tf")
Test-Assertion $mainDmsExists "Descriptive file name 'main-dms.tf' used" "Should use descriptive file name instead of generic 'main.tf'"

$genericMainExists = Test-Path (Join-Path $ModulePath "main.tf")
Test-Assertion (-not $genericMainExists) "Generic 'main.tf' not present" "Should not use generic 'main.tf' filename"

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Green
Write-Host "Total Tests: $TestCount" -ForegroundColor Yellow
Write-Host "Passed: $($TestCount - $ErrorCount)" -ForegroundColor Green
Write-Host "Failed: $ErrorCount" -ForegroundColor $(if ($ErrorCount -eq 0) { "Green" } else { "Red" })

if ($ErrorCount -eq 0) {
    Write-Host "`n🎉 All resource naming consistency tests passed!" -ForegroundColor Green
    Write-Host "✅ Property 1: Resource Naming Consistency - VALIDATED" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n❌ Some resource naming consistency tests failed!" -ForegroundColor Red
    Write-Host "Please fix the issues above before proceeding." -ForegroundColor Yellow
    exit 1
}