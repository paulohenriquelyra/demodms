# Property Test 8: AWS Security Best Practices Enforcement
# Feature: dms-module-refactoring, Property 8: AWS Security Best Practices Enforcement
# Validates: Requirements 13.1, 13.2, 13.3, 13.4, 13.5
param(
    [string]$ModulePath = ".",
    [switch]$Verbose
)

Write-Host "=== Property Test 8: AWS Security Best Practices Enforcement ===" -ForegroundColor Cyan
Write-Host "Validating AWS Well-Architected Framework compliance and security best practices" -ForegroundColor White

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

# Test 1: KMS Encryption Enforcement (Requirement 13.3)
Write-Host "`n--- Test 1: KMS Encryption Enforcement ---" -ForegroundColor Blue

# Check for security_config variable with environment-aware KMS enforcement
if ($VariablesContent -match 'variable\s+"security_config".*require_kms_encryption.*null.*auto-detect') {
    Write-Host "✅ security_config variable with environment-aware KMS enforcement found" -ForegroundColor Green
    $TestResults += @{ Test = "SecurityConfigVariable"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: security_config variable with environment-aware KMS enforcement missing" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "SecurityConfigVariable"; Status = "FAIL" }
}

# Check for KMS validation with environment awareness in variables
if ($VariablesContent -match 'require_kms_encryption.*!=.*false.*production') {
    Write-Host "✅ Environment-aware KMS encryption validation found in variables" -ForegroundColor Green
    $TestResults += @{ Test = "KmsValidation"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Environment-aware KMS encryption validation missing in variables" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "KmsValidation"; Status = "FAIL" }
}

# Check for conditional KMS encryption in locals
if ($LocalsContent -match 'kms_encryption_required.*security_config\.require_kms_encryption') {
    Write-Host "✅ Conditional KMS encryption logic found in locals" -ForegroundColor Green
    $TestResults += @{ Test = "ConditionalKmsLogic"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Conditional KMS encryption logic missing in locals" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "ConditionalKmsLogic"; Status = "FAIL" }
}

# Check for KMS enforcement in resources
$KmsEnforcementCount = ($MainContent | Select-String -Pattern "local\.security_settings\.kms_encryption_required.*var\.kms_key_arn" -AllMatches).Matches.Count
if ($KmsEnforcementCount -ge 2) {
    Write-Host "✅ KMS encryption enforced in resources ($KmsEnforcementCount instances)" -ForegroundColor Green
    $TestResults += @{ Test = "KmsResourceEnforcement"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: KMS encryption not properly enforced in resources ($KmsEnforcementCount instances)" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "KmsResourceEnforcement"; Status = "FAIL" }
}

# Test 2: Network Isolation and Security Groups (Requirement 13.4)
Write-Host "`n--- Test 2: Network Isolation and Security Groups ---" -ForegroundColor Blue

# Check for network security configuration in locals
if ($LocalsContent -match 'network_security.*network_isolation_level') {
    Write-Host "✅ Network security configuration found in locals" -ForegroundColor Green
    $TestResults += @{ Test = "NetworkSecurityConfig"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Network security configuration missing in locals" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "NetworkSecurityConfig"; Status = "FAIL" }
}

# Check for configurable isolation levels
if ($VariablesContent -match 'network_isolation_level.*strict.*standard.*basic') {
    Write-Host "✅ Configurable network isolation levels found" -ForegroundColor Green
    $TestResults += @{ Test = "IsolationLevels"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Configurable network isolation levels missing" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "IsolationLevels"; Status = "FAIL" }
}

# Check for dynamic security group rules
if ($MainContent -match 'dynamic\s+"egress".*network_security') {
    Write-Host "✅ Dynamic security group rules found" -ForegroundColor Green
    $TestResults += @{ Test = "DynamicSecurityRules"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Dynamic security group rules missing" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "DynamicSecurityRules"; Status = "FAIL" }
}

# Check for public access restriction
if ($MainContent -match 'publicly_accessible.*local\.security_settings\.publicly_accessible') {
    Write-Host "✅ Public access restriction enforced" -ForegroundColor Green
    $TestResults += @{ Test = "PublicAccessRestriction"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Public access restriction not enforced" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "PublicAccessRestriction"; Status = "FAIL" }
}

# Test 3: Multi-AZ Support Configuration (Requirement 13.5)
Write-Host "`n--- Test 3: Multi-AZ Support Configuration ---" -ForegroundColor Blue

# Check for multi_az_config variable
if ($VariablesContent -match 'variable\s+"multi_az_config".*enable_multi_az.*force_multi_az_production') {
    Write-Host "✅ multi_az_config variable found with production enforcement" -ForegroundColor Green
    $TestResults += @{ Test = "MultiAzConfigVariable"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: multi_az_config variable missing or incomplete" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "MultiAzConfigVariable"; Status = "FAIL" }
}

# Check for Multi-AZ logic in locals
if ($LocalsContent -match 'multi_az_enabled.*force_multi_az_production.*is_production') {
    Write-Host "✅ Multi-AZ production enforcement logic found" -ForegroundColor Green
    $TestResults += @{ Test = "MultiAzProductionLogic"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Multi-AZ production enforcement logic missing" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "MultiAzProductionLogic"; Status = "FAIL" }
}

# Check for Multi-AZ in DMS instance
if ($MainContent -match 'multi_az.*local\.security_settings\.multi_az_enabled') {
    Write-Host "✅ Multi-AZ configuration applied to DMS instance" -ForegroundColor Green
    $TestResults += @{ Test = "MultiAzDmsInstance"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Multi-AZ configuration not applied to DMS instance" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "MultiAzDmsInstance"; Status = "FAIL" }
}

# Test 4: SSL/TLS Enforcement (Requirement 13.2)
Write-Host "`n--- Test 4: SSL/TLS Enforcement ---" -ForegroundColor Blue

# Check for SSL enforcement configuration
if ($VariablesContent -match 'enforce_ssl.*bool.*true') {
    Write-Host "✅ SSL enforcement configuration found" -ForegroundColor Green
    $TestResults += @{ Test = "SslEnforcementConfig"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: SSL enforcement configuration missing" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "SslEnforcementConfig"; Status = "FAIL" }
}

# Check for SSL mode logic in locals
if ($LocalsContent -match 'ssl_mode_source.*enforce_ssl.*require') {
    Write-Host "✅ SSL mode enforcement logic found for source" -ForegroundColor Green
    $TestResults += @{ Test = "SslModeSourceLogic"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: SSL mode enforcement logic missing for source" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "SslModeSourceLogic"; Status = "FAIL" }
}

if ($LocalsContent -match 'ssl_mode_target.*enforce_ssl.*require') {
    Write-Host "✅ SSL mode enforcement logic found for target" -ForegroundColor Green
    $TestResults += @{ Test = "SslModeTargetLogic"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: SSL mode enforcement logic missing for target" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "SslModeTargetLogic"; Status = "FAIL" }
}

# Check for SSL enforcement in endpoints
$SslEnforcementCount = ($MainContent | Select-String -Pattern "ssl_mode.*local\.security_settings\.ssl_mode" -AllMatches).Matches.Count
if ($SslEnforcementCount -ge 2) {
    Write-Host "✅ SSL enforcement applied to endpoints ($SslEnforcementCount instances)" -ForegroundColor Green
    $TestResults += @{ Test = "SslEndpointEnforcement"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: SSL enforcement not applied to endpoints ($SslEnforcementCount instances)" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "SslEndpointEnforcement"; Status = "FAIL" }
}

# Test 5: Enhanced Monitoring and Performance Insights
Write-Host "`n--- Test 5: Enhanced Monitoring and Performance Insights ---" -ForegroundColor Blue

# Check for monitoring configuration
if ($VariablesContent -match 'enable_detailed_monitoring.*enable_performance_insights') {
    Write-Host "✅ Monitoring configuration variables found" -ForegroundColor Green
    $TestResults += @{ Test = "MonitoringConfigVariables"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Monitoring configuration variables missing" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "MonitoringConfigVariables"; Status = "FAIL" }
}

# Check for IAM role for monitoring
if ($MainContent -match 'resource\s+"aws_iam_role"\s+"dms_monitoring"') {
    Write-Host "✅ IAM role for DMS monitoring found" -ForegroundColor Green
    $TestResults += @{ Test = "MonitoringIamRole"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: IAM role for DMS monitoring missing" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "MonitoringIamRole"; Status = "FAIL" }
}

# Check for monitoring interval configuration
if ($MainContent -match 'monitoring_interval.*monitoring_enabled.*60') {
    Write-Host "✅ Monitoring interval configuration found" -ForegroundColor Green
    $TestResults += @{ Test = "MonitoringInterval"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Monitoring interval configuration missing" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "MonitoringInterval"; Status = "FAIL" }
}

# Test 6: AWS Well-Architected Framework Compliance (Requirement 13.1)
Write-Host "`n--- Test 6: AWS Well-Architected Framework Compliance ---" -ForegroundColor Blue

# Check for compliance configuration in locals
if ($LocalsContent -match 'compliance_config.*Security Pillar.*Reliability Pillar.*Performance Efficiency') {
    Write-Host "✅ AWS Well-Architected compliance configuration found" -ForegroundColor Green
    $TestResults += @{ Test = "WellArchitectedCompliance"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: AWS Well-Architected compliance configuration missing" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "WellArchitectedCompliance"; Status = "FAIL" }
}

# Check for security validations in lifecycle blocks
$SecurityValidationCount = ($MainContent | Select-String -Pattern "precondition.*security.*compliance" -AllMatches).Matches.Count
if ($SecurityValidationCount -ge 3) {
    Write-Host "✅ Security validations found in lifecycle blocks ($SecurityValidationCount instances)" -ForegroundColor Green
    $TestResults += @{ Test = "SecurityValidations"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Insufficient security validations in lifecycle blocks ($SecurityValidationCount instances)" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "SecurityValidations"; Status = "FAIL" }
}

# Check for production-specific security requirements
if ($MainContent -match 'is_production.*ssl.*kms.*multi_az.*monitoring') {
    Write-Host "✅ Production-specific security requirements found" -ForegroundColor Green
    $TestResults += @{ Test = "ProductionSecurityRequirements"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Production-specific security requirements missing" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "ProductionSecurityRequirements"; Status = "FAIL" }
}

# Test 7: Deletion Protection and Backup Configuration
Write-Host "`n--- Test 7: Deletion Protection and Backup Configuration ---" -ForegroundColor Blue

# Check for deletion protection configuration
if ($LocalsContent -match 'deletion_protection.*enable_deletion_protection.*is_production') {
    Write-Host "✅ Deletion protection configuration found" -ForegroundColor Green
    $TestResults += @{ Test = "DeletionProtectionConfig"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Deletion protection configuration missing" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "DeletionProtectionConfig"; Status = "FAIL" }
}

# Check for backup retention configuration
if ($VariablesContent -match 'backup_retention_days.*1.*35') {
    Write-Host "✅ Backup retention validation found" -ForegroundColor Green
    $TestResults += @{ Test = "BackupRetentionValidation"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Backup retention validation missing" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "BackupRetentionValidation"; Status = "FAIL" }
}

# Test 8: Cost Optimization and Environment-Based Configuration
Write-Host "`n--- Test 8: Cost Optimization and Environment-Based Configuration ---" -ForegroundColor Blue

# Check for cost optimization configuration in locals
if ($LocalsContent -match 'cost_optimization.*performance_insights_cost_impact.*HIGH.*NONE') {
    Write-Host "✅ Cost optimization configuration found in locals" -ForegroundColor Green
    $TestResults += @{ Test = "CostOptimizationConfig"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Cost optimization configuration missing in locals" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "CostOptimizationConfig"; Status = "FAIL" }
}

# Check for environment-based auto-detection logic
if ($LocalsContent -match 'enable_performance_insights.*!=.*null.*is_production.*true.*false') {
    Write-Host "✅ Environment-based Performance Insights auto-detection found" -ForegroundColor Green
    $TestResults += @{ Test = "PerformanceInsightsAutoDetection"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Environment-based Performance Insights auto-detection missing" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "PerformanceInsightsAutoDetection"; Status = "FAIL" }
}

# Check for environment-based monitoring logic
if ($LocalsContent -match 'enable_detailed_monitoring.*!=.*null.*staging.*stage.*true.*false') {
    Write-Host "✅ Environment-based detailed monitoring auto-detection found" -ForegroundColor Green
    $TestResults += @{ Test = "DetailedMonitoringAutoDetection"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Environment-based detailed monitoring auto-detection missing" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "DetailedMonitoringAutoDetection"; Status = "FAIL" }
}

# Check for cost impact warnings in validations
if ($MainContent -match 'Performance Insights.*cost implications.*auto-disabled.*non-production') {
    Write-Host "✅ Cost impact warnings found in validations" -ForegroundColor Green
    $TestResults += @{ Test = "CostImpactWarnings"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Cost impact warnings missing in validations" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "CostImpactWarnings"; Status = "FAIL" }
}

# Test 8: Cost Optimization and Environment-Based Configuration
Write-Host "`n--- Test 8: Cost Optimization and Environment-Based Configuration ---" -ForegroundColor Blue

# Check for cost optimization configuration in locals
if ($LocalsContent -match 'cost_optimization.*performance_insights_cost_impact.*HIGH.*NONE') {
    Write-Host "✅ Cost optimization configuration found in locals" -ForegroundColor Green
    $TestResults += @{ Test = "CostOptimizationConfig"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Cost optimization configuration missing in locals" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "CostOptimizationConfig"; Status = "FAIL" }
}

# Check for environment-based auto-detection logic
if ($LocalsContent -match 'enable_performance_insights.*!=.*null.*is_production.*true.*false') {
    Write-Host "✅ Environment-based Performance Insights auto-detection found" -ForegroundColor Green
    $TestResults += @{ Test = "PerformanceInsightsAutoDetection"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Environment-based Performance Insights auto-detection missing" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "PerformanceInsightsAutoDetection"; Status = "FAIL" }
}

# Check for environment-based monitoring logic
if ($LocalsContent -match 'enable_detailed_monitoring.*!=.*null.*staging.*stage.*true.*false') {
    Write-Host "✅ Environment-based detailed monitoring auto-detection found" -ForegroundColor Green
    $TestResults += @{ Test = "DetailedMonitoringAutoDetection"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Environment-based detailed monitoring auto-detection missing" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "DetailedMonitoringAutoDetection"; Status = "FAIL" }
}

# Check for cost impact warnings in validations
if ($MainContent -match 'Performance Insights.*cost implications.*auto-disabled.*non-production') {
    Write-Host "✅ Cost impact warnings found in validations" -ForegroundColor Green
    $TestResults += @{ Test = "CostImpactWarnings"; Status = "PASS" }
} else {
    Write-Host "❌ FAIL: Cost impact warnings missing in validations" -ForegroundColor Red
    $ErrorCount++
    $TestResults += @{ Test = "CostImpactWarnings"; Status = "FAIL" }
}

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

# AWS Well-Architected Framework Validation
Write-Host "`n=== AWS Well-Architected Framework Validation ===" -ForegroundColor Cyan

$SecurityPillarTests = @("SecurityConfigVariable", "KmsValidation", "ConditionalKmsLogic", "KmsResourceEnforcement", "SslEnforcementConfig", "SslModeSourceLogic", "SslModeTargetLogic", "SslEndpointEnforcement")
$ReliabilityPillarTests = @("MultiAzConfigVariable", "MultiAzProductionLogic", "MultiAzDmsInstance", "BackupRetentionValidation")
$PerformancePillarTests = @("MonitoringConfigVariables", "MonitoringIamRole", "MonitoringInterval", "PerformanceInsightsAutoDetection")
$OperationalPillarTests = @("WellArchitectedCompliance", "SecurityValidations", "ProductionSecurityRequirements")
$CostOptimizationTests = @("CostOptimizationConfig", "DetailedMonitoringAutoDetection", "CostImpactWarnings")

$SecurityPassed = ($TestResults | Where-Object { $_.Test -in $SecurityPillarTests -and $_.Status -eq "PASS" }).Count
$ReliabilityPassed = ($TestResults | Where-Object { $_.Test -in $ReliabilityPillarTests -and $_.Status -eq "PASS" }).Count
$PerformancePassed = ($TestResults | Where-Object { $_.Test -in $PerformancePillarTests -and $_.Status -eq "PASS" }).Count
$OperationalPassed = ($TestResults | Where-Object { $_.Test -in $OperationalPillarTests -and $_.Status -eq "PASS" }).Count
$CostOptimizationPassed = ($TestResults | Where-Object { $_.Test -in $CostOptimizationTests -and $_.Status -eq "PASS" }).Count

Write-Host "Security Pillar: $SecurityPassed/$($SecurityPillarTests.Count) tests passed" -ForegroundColor $(if ($SecurityPassed -eq $SecurityPillarTests.Count) { "Green" } else { "Red" })
Write-Host "Reliability Pillar: $ReliabilityPassed/$($ReliabilityPillarTests.Count) tests passed" -ForegroundColor $(if ($ReliabilityPassed -eq $ReliabilityPillarTests.Count) { "Green" } else { "Red" })
Write-Host "Performance Efficiency Pillar: $PerformancePassed/$($PerformancePillarTests.Count) tests passed" -ForegroundColor $(if ($PerformancePassed -eq $PerformancePillarTests.Count) { "Green" } else { "Red" })
Write-Host "Operational Excellence Pillar: $OperationalPassed/$($OperationalPillarTests.Count) tests passed" -ForegroundColor $(if ($OperationalPassed -eq $OperationalPillarTests.Count) { "Green" } else { "Red" })
Write-Host "Cost Optimization Pillar: $CostOptimizationPassed/$($CostOptimizationTests.Count) tests passed" -ForegroundColor $(if ($CostOptimizationPassed -eq $CostOptimizationTests.Count) { "Green" } else { "Red" })

# Final validation
Write-Host "`n=== Property Validation ===" -ForegroundColor Cyan

if ($ErrorCount -eq 0) {
    Write-Host "🎉 PROPERTY VALIDATED: AWS Security Best Practices Enforcement" -ForegroundColor Green
    Write-Host "✅ Requirements 13.1, 13.2, 13.3, 13.4, 13.5 validated successfully" -ForegroundColor Green
    Write-Host "✅ AWS Well-Architected Framework compliance verified" -ForegroundColor Green
    Write-Host "✅ All security pillars validated with cost optimization" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ PROPERTY VIOLATION: AWS Security Best Practices Enforcement" -ForegroundColor Red
    Write-Host "❌ $ErrorCount security best practice violations found" -ForegroundColor Red
    Write-Host "Please review the failed tests and implement the required security enhancements." -ForegroundColor Red
    exit 1
}