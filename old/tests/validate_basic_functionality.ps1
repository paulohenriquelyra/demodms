# Basic Functionality Test for DMS Module
# Validates that the module has been simplified and CI/CD references removed
param(
    [string]$ModulePath = ".",
    [switch]$Verbose
)

Write-Host "=== Basic DMS Module Functionality Test ===" -ForegroundColor Cyan
Write-Host "Validating simplified module without CI/CD pipeline dependencies" -ForegroundColor White

$ErrorCount = 0
$TestResults = @()

# Test files
$TestFiles = @("variables.tf", "main-dms.tf", "locals.tf")

foreach ($File in $TestFiles) {
    $FilePath = Join-Path $ModulePath $File
    if (-not (Test-Path $FilePath)) {
        Write-Host "❌ FAIL: Required file not found: $File" -ForegroundColor Red
        $ErrorCount++
        continue
    }
    Write-Host "✅ Found required file: $File" -ForegroundColor Green
}

if ($ErrorCount -gt 0) {
    Write-Host "❌ CRITICAL: Missing required files." -ForegroundColor Red
    exit 1
}

# Read file contents
$VariablesContent = Get-Content (Join-Path $ModulePath "variables.tf") -Raw
$MainContent = Get-Content (Join-Path $ModulePath "main-dms.tf") -Raw
$LocalsContent = Get-Content (Join-Path $ModulePath "locals.tf") -Raw

# Test 1: Verify CI/CD references have been removed
Write-Host "`n--- Test 1: CI/CD References Removed ---" -ForegroundColor Blue

$CICDReferences = @(
    "Azure DevOps",
    "enable_lifecycle_rules",
    "CI/CD automation",
    "pipeline"
)

$CICDFound = $false
foreach ($Reference in $CICDReferences) {
    if ($VariablesContent -match $Reference -or $MainContent -match $Reference -or $LocalsContent -match $Reference) {
        Write-Host "❌ FAIL: Found CI/CD reference: $Reference" -ForegroundColor Red
        $CICDFound = $true
        $ErrorCount++
    }
}

if (-not $CICDFound) {
    Write-Host "✅ CI/CD references successfully removed" -ForegroundColor Green
    $TestResults += @{ Test = "CICDReferencesRemoved"; Status = "PASS" }
} else {
    $TestResults += @{ Test = "CICDReferencesRemoved"; Status = "FAIL" }
}

# Test 2: Verify lifecycle_config variable has been removed
Write-Host "`n--- Test 2: Lifecycle Config Variable Removed ---" -ForegroundColor Blue

if ($VariablesContent -match 'variable\s+"lifecycle_config"') {
    Write-Host "❌ FAIL: lifecycle_config variable still exists" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "LifecycleConfigRemoved"; Status = "FAIL" }
} else {
    Write-Host "✅ lifecycle_config variable successfully removed" -ForegroundColor Green
    $TestResults += @{ Test = "LifecycleConfigRemoved"; Status = "PASS" }
}

# Test 3: Verify lifecycle blocks have been removed from resources
Write-Host "`n--- Test 3: Lifecycle Blocks Removed ---" -ForegroundColor Blue

if ($MainContent -match 'lifecycle\s*\{') {
    Write-Host "❌ FAIL: lifecycle blocks still exist in main-dms.tf" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "LifecycleBlocksRemoved"; Status = "FAIL" }
} else {
    Write-Host "✅ lifecycle blocks successfully removed" -ForegroundColor Green
    $TestResults += @{ Test = "LifecycleBlocksRemoved"; Status = "PASS" }
}

# Test 4: Verify essential DMS resources are still present
Write-Host "`n--- Test 4: Essential DMS Resources Present ---" -ForegroundColor Blue

$EssentialResources = @(
    "aws_dms_replication_instance",
    "aws_dms_replication_subnet_group",
    "aws_dms_endpoint.*source",
    "aws_dms_endpoint.*target",
    "aws_dms_replication_task",
    "aws_security_group"
)

$AllResourcesFound = $true
foreach ($Resource in $EssentialResources) {
    if ($MainContent -match $Resource) {
        Write-Host "✅ Found essential resource: $Resource" -ForegroundColor Green
    } else {
        Write-Host "❌ FAIL: Missing essential resource: $Resource" -ForegroundColor Red
        $AllResourcesFound = $false
        $ErrorCount++
    }
}

if ($AllResourcesFound) {
    $TestResults += @{ Test = "EssentialResourcesPresent"; Status = "PASS" }
} else {
    $TestResults += @{ Test = "EssentialResourcesPresent"; Status = "FAIL" }
}

# Test 5: Verify Terraform validation passes
Write-Host "`n--- Test 5: Terraform Validation ---" -ForegroundColor Blue

try {
    $ValidationResult = wsl terraform validate 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Terraform validation passed" -ForegroundColor Green
        $TestResults += @{ Test = "TerraformValidation"; Status = "PASS" }
    } else {
        Write-Host "❌ FAIL: Terraform validation failed" -ForegroundColor Red
        Write-Host "Error: $ValidationResult" -ForegroundColor Red
        $ErrorCount++
        $TestResults += @{ Test = "TerraformValidation"; Status = "FAIL" }
    }
} catch {
    Write-Host "❌ FAIL: Could not run terraform validate" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "TerraformValidation"; Status = "FAIL" }
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
$PassedTests = ($TestResults | Where-Object { $_.Status -eq "PASS" }).Count
$FailedTests = ($TestResults | Where-Object { $_.Status -eq "FAIL" }).Count
$TotalTests = $TestResults.Count

Write-Host "Total Tests: $TotalTests" -ForegroundColor White
Write-Host "Passed: $PassedTests" -ForegroundColor Green
Write-Host "Failed: $FailedTests" -ForegroundColor Red

if ($Verbose) {
    Write-Host "`n--- Detailed Results ---" -ForegroundColor Yellow
    foreach ($Result in $TestResults) {
        $Color = if ($Result.Status -eq "PASS") { "Green" } else { "Red" }
        $Symbol = if ($Result.Status -eq "PASS") { "✅" } else { "❌" }
        Write-Host "$Symbol $($Result.Test): $($Result.Status)" -ForegroundColor $Color
    }
}

# Final validation
Write-Host "`n=== Module Simplification Validation ===" -ForegroundColor Cyan

if ($ErrorCount -eq 0) {
    Write-Host "🎉 SUCCESS: DMS Module Successfully Simplified" -ForegroundColor Green
    Write-Host "✅ All CI/CD pipeline dependencies removed" -ForegroundColor Green
    Write-Host "✅ Module is ready for client customization" -ForegroundColor Green
    Write-Host "✅ Terraform validation passes" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ FAILURE: Module simplification incomplete" -ForegroundColor Red
    Write-Host "❌ $ErrorCount issues found" -ForegroundColor Red
    Write-Host "Please review the failed tests and complete the simplification." -ForegroundColor Red
    exit 1
}