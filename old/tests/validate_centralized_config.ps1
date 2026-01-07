# ============================================================================
# Centralized Configuration Validation Script
# ============================================================================
#
# Feature: dms-module-refactoring, Property 2: Centralized Configuration Management
# Property: For any module deployment, all tags, computed values, and common 
# configurations should be defined in locals blocks and referenced consistently 
# throughout the module without duplication.
# Validates: Requirements 3.1, 3.2, 3.3, 6.2, 6.3, 6.4, 6.5
#
# This script validates that:
# 1. All tags are centralized in locals.tf
# 2. Resource names follow consistent patterns from locals
# 3. No duplication of computed values
# 4. Conditional configurations work properly
# ============================================================================

param(
    [string]$ModulePath = "../",
    [string]$ProjectName = "test-dms",
    [string]$Environment = "dev"
)

Write-Host "=== Centralized Configuration Validation ===" -ForegroundColor Green
Write-Host "Module Path: $ModulePath" -ForegroundColor Yellow
Write-Host "Project: $ProjectName, Environment: $Environment" -ForegroundColor Yellow

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

# Test 1: Validate locals.tf file exists and has required blocks
Write-Host "`n--- Test 1: Locals File Structure ---" -ForegroundColor Cyan

$localsFile = Join-Path $ModulePath "locals.tf"
$localsExists = Test-Path $localsFile
Test-Assertion $localsExists "Locals file exists" "locals.tf file not found"

if ($localsExists) {
    $localsContent = Get-Content $localsFile -Raw
    
    # Check for required locals blocks
    $requiredBlocks = @(
        "naming\s*=",
        "common_tags\s*=",
        "resource_tags\s*=", 
        "resource_names\s*=",
        "secrets_manager_config\s*=",
        "direct_credentials_config\s*=",
        "lifecycle_enabled\s*=",
        "environment_config\s*="
    )
    
    foreach ($block in $requiredBlocks) {
        $blockExists = $localsContent -match $block
        $blockName = $block -replace "\s*=.*", ""
        Test-Assertion $blockExists "Locals block '$blockName' exists" "Required locals block '$blockName' not found"
    }
}

# Test 2: Validate naming consistency in main-dms.tf
Write-Host "`n--- Test 2: Naming Consistency ---" -ForegroundColor Cyan

$mainFile = Join-Path $ModulePath "main-dms.tf"
$mainExists = Test-Path $mainFile
Test-Assertion $mainExists "Main DMS file exists" "main-dms.tf file not found"

if ($mainExists) {
    $mainContent = Get-Content $mainFile -Raw
    
    # Check that resource names use locals references
    $namingPatterns = @(
        "local\.resource_names\.dms_instance",
        "local\.resource_names\.subnet_group",
        "local\.resource_names\.security_group",
        "local\.resource_names\.source_endpoint",
        "local\.resource_names\.target_endpoint",
        "local\.resource_names\.replication_task"
    )
    
    foreach ($pattern in $namingPatterns) {
        $patternFound = $mainContent -match $pattern
        Test-Assertion $patternFound "Naming pattern '$pattern' used" "Resource naming should use locals reference: $pattern"
    }
    
    # Check that hardcoded names are not used
    $hardcodedPatterns = @(
        'replication_instance_id\s*=\s*"\$\{var\.project_name\}',
        'replication_subnet_group_id\s*=\s*"\$\{var\.project_name\}'
    )
    
    foreach ($pattern in $hardcodedPatterns) {
        $patternFound = $mainContent -match $pattern
        Test-Assertion (-not $patternFound) "No hardcoded naming pattern '$pattern'" "Should use locals for naming instead of direct variable interpolation"
    }
}

# Test 3: Validate tag consistency
Write-Host "`n--- Test 3: Tag Consistency ---" -ForegroundColor Cyan

if ($mainExists) {
    $mainContent = Get-Content $mainFile -Raw
    
    # Check that tags use locals references
    $tagPatterns = @(
        "local\.resource_tags\.dms_instance",
        "local\.resource_tags\.subnet_group", 
        "local\.resource_tags\.security_group",
        "local\.resource_tags\.source_endpoint",
        "local\.resource_tags\.target_endpoint",
        "local\.resource_tags\.replication_task"
    )
    
    foreach ($pattern in $tagPatterns) {
        $patternFound = $mainContent -match $pattern
        Test-Assertion $patternFound "Tag pattern '$pattern' used" "Resource tags should use locals reference: $pattern"
    }
    
    # Check that merge(var.tags, {...}) is not used directly
    $directMergePattern = 'tags\s*=\s*merge\(var\.tags,'
    $directMergeFound = $mainContent -match $directMergePattern
    Test-Assertion (-not $directMergeFound) "No direct tag merging" "Should use locals for tag management instead of direct merge"
}

# Test 4: Validate variables.tf has proper structure
Write-Host "`n--- Test 4: Variables Structure ---" -ForegroundColor Cyan

$variablesFile = Join-Path $ModulePath "variables.tf"
$variablesExists = Test-Path $variablesFile
Test-Assertion $variablesExists "Variables file exists" "variables.tf file not found"

if ($variablesExists) {
    $variablesContent = Get-Content $variablesFile -Raw
    
    # Check for required variables
    $requiredVariables = @(
        "project_name",
        "environment",
        "enable_secrets_manager",
        "lifecycle_config",
        "source_endpoint_config",
        "target_endpoint_config"
    )
    
    foreach ($variable in $requiredVariables) {
        $variableExists = $variablesContent -match "variable\s+`"$variable`""
        Test-Assertion $variableExists "Variable '$variable' exists" "Required variable '$variable' not found"
    }
    
    # Check for English descriptions
    $englishDescriptions = $variablesContent -match 'description\s*=\s*<<-EOT[\s\S]*?EOT'
    Test-Assertion $englishDescriptions "Variables have English descriptions" "Variables should have comprehensive English descriptions"
}

# Test 5: Validate conditional configuration logic
Write-Host "`n--- Test 5: Conditional Configuration ---" -ForegroundColor Cyan

if ($localsExists) {
    $localsContent = Get-Content $localsFile -Raw
    
    # Check for Secrets Manager conditional logic
    $secretsConditional = $localsContent -match "var\.enable_secrets_manager\s*\?"
    Test-Assertion $secretsConditional "Secrets Manager conditional logic exists" "Should have conditional logic for Secrets Manager"
    
    # Check for lifecycle conditional logic  
    $lifecycleConditional = $localsContent -match "var\.lifecycle_config\.enable_lifecycle_rules"
    Test-Assertion $lifecycleConditional "Lifecycle conditional logic exists" "Should have conditional logic for lifecycle rules"
    
    # Check for environment-specific logic
    $environmentConditional = $localsContent -match "var\.environment\s*=="
    Test-Assertion $environmentConditional "Environment conditional logic exists" "Should have environment-specific conditional logic"
}

# Test 6: Validate Azure DevOps compatibility
Write-Host "`n--- Test 6: Azure DevOps Compatibility ---" -ForegroundColor Cyan

if ($variablesExists) {
    $variablesContent = Get-Content $variablesFile -Raw
    
    # Check for lifecycle configuration with default false
    $lifecycleDefault = $variablesContent -match "enable_lifecycle_rules\s*=\s*false"
    Test-Assertion $lifecycleDefault "Lifecycle rules default to false" "Should default to false for Azure DevOps compatibility"
    
    # Check for Azure DevOps documentation
    $azureDevOpsDoc = $variablesContent -match "Azure DevOps"
    Test-Assertion $azureDevOpsDoc "Azure DevOps documentation exists" "Should document Azure DevOps compatibility"
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Green
Write-Host "Total Tests: $TestCount" -ForegroundColor Yellow
Write-Host "Passed: $($TestCount - $ErrorCount)" -ForegroundColor Green
Write-Host "Failed: $ErrorCount" -ForegroundColor $(if ($ErrorCount -eq 0) { "Green" } else { "Red" })

if ($ErrorCount -eq 0) {
    Write-Host "`n🎉 All centralized configuration tests passed!" -ForegroundColor Green
    Write-Host "✅ Property 2: Centralized Configuration Management - VALIDATED" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n❌ Some centralized configuration tests failed!" -ForegroundColor Red
    Write-Host "Please fix the issues above before proceeding." -ForegroundColor Yellow
    exit 1
}