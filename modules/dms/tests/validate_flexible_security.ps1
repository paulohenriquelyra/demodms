# Property Test 6: Flexible Security Configuration
param(
    [string]$ModulePath = ".",
    [switch]$Verbose
)

Write-Host "=== Property Test 6: Flexible Security Configuration ===" -ForegroundColor Cyan

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

# Test 1: Secrets Manager Variable Configuration
Write-Host "`n--- Test 1: Secrets Manager Variable Configuration ---" -ForegroundColor Blue
$VariablesContent = Get-Content (Join-Path $ModulePath "variables.tf") -Raw

if ($VariablesContent -match 'variable\s+"enable_secrets_manager"') {
    Write-Host "✅ enable_secrets_manager variable found" -ForegroundColor Green
    $TestResults += @{ Test = "SecretsManagerVariable"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: enable_secrets_manager variable not found" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "SecretsManagerVariable"; Status = "FAIL" }
}

# Test 2: Conditional Logic in Locals
Write-Host "`n--- Test 2: Conditional Logic in Locals ---" -ForegroundColor Blue
$LocalsContent = Get-Content (Join-Path $ModulePath "locals.tf") -Raw

if ($LocalsContent -match 'secrets_manager_config.*var\.enable_secrets_manager') {
    Write-Host "✅ Secrets Manager conditional logic found" -ForegroundColor Green
    $TestResults += @{ Test = "SecretsManagerConditional"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Secrets Manager conditional logic missing" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "SecretsManagerConditional"; Status = "FAIL" }
}

if ($LocalsContent -match 'direct_credentials_config.*var\.enable_secrets_manager.*null') {
    Write-Host "✅ Direct credentials conditional logic found" -ForegroundColor Green
    $TestResults += @{ Test = "DirectCredentialsConditional"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Direct credentials conditional logic missing" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "DirectCredentialsConditional"; Status = "FAIL" }
}

# Test 3: Main DMS Resource Configuration
Write-Host "`n--- Test 3: Main DMS Resource Configuration ---" -ForegroundColor Blue
$MainContent = Get-Content (Join-Path $ModulePath "main-dms.tf") -Raw

if ($MainContent -match 'secrets_manager_arn.*local\.secrets_manager_config') {
    Write-Host "✅ Conditional credential configuration found" -ForegroundColor Green
    $TestResults += @{ Test = "ConditionalCredentials"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Conditional credential configuration missing" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "ConditionalCredentials"; Status = "FAIL" }
}

# Test 4: Security Best Practices
Write-Host "`n--- Test 4: Security Best Practices ---" -ForegroundColor Blue

$KmsCount = ($MainContent | Select-String -Pattern "kms_key_arn\s*=\s*var\.kms_key_arn" -AllMatches).Matches.Count
if ($KmsCount -ge 3) {
    Write-Host "✅ KMS encryption enforced ($KmsCount instances)" -ForegroundColor Green
    $TestResults += @{ Test = "KmsEncryption"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: KMS encryption not enforced ($KmsCount instances)" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "KmsEncryption"; Status = "FAIL" }
}

if ($MainContent -match 'publicly_accessible\s*=\s*false') {
    Write-Host "✅ Private access enforced" -ForegroundColor Green
    $TestResults += @{ Test = "PrivateAccess"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Private access not enforced" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "PrivateAccess"; Status = "FAIL" }
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
Write-Host "`n=== Property Validation ===" -ForegroundColor Cyan

if ($ErrorCount -eq 0) {
    Write-Host "🎉 PROPERTY VALIDATED: Flexible Security Configuration" -ForegroundColor Green
    Write-Host "✅ Requirements 11.1-11.4 validated successfully" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ PROPERTY VIOLATION: Flexible Security Configuration" -ForegroundColor Red
    Write-Host "Please review the failed tests and fix the issues." -ForegroundColor Red
    exit 1
}