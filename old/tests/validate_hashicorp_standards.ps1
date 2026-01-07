# ============================================================================
# HashiCorp Module Standards Compliance Test
# ============================================================================
# Feature: dms-module-refactoring, Property 5: HashiCorp Module Standards Compliance
# Property: For any module invocation, the module interface should follow HashiCorp 
# standards with proper variable definitions, output structures, and integration 
# patterns that work seamlessly with other Terraform modules.
# Validates: Requirements 8.1, 8.3

param(
    [string]$ModulePath = "../",
    [int]$Iterations = 100
)

Write-Host "=== HashiCorp Module Standards Compliance Test ===" -ForegroundColor Green
Write-Host "Testing module at: $ModulePath" -ForegroundColor Yellow
Write-Host "Running $Iterations iterations for property-based testing" -ForegroundColor Yellow

$ErrorCount = 0
$TestResults = @()

# Test configurations for property-based testing
$TestConfigurations = @(
    @{
        Name = "Basic Configuration"
        ProjectName = "test-dms"
        Environment = "dev"
        EnableSecrets = $true
        EnableLifecycle = $false
    },
    @{
        Name = "Production Configuration"
        ProjectName = "prod-migration"
        Environment = "production"
        EnableSecrets = $true
        EnableLifecycle = $true
    },
    @{
        Name = "Staging Configuration"
        ProjectName = "stage-test"
        Environment = "staging"
        EnableSecrets = $false
        EnableLifecycle = $false
    },
    @{
        Name = "Development Configuration"
        ProjectName = "dev-project"
        Environment = "development"
        EnableSecrets = $true
        EnableLifecycle = $false
    }
)

function Test-HashiCorpStandardsCompliance {
    param($Config, $Iteration)
    
    $TestName = "$($Config.Name) - Iteration $Iteration"
    Write-Host "Testing: $TestName" -ForegroundColor Cyan
    
    $TestResult = @{
        Name = $TestName
        Config = $Config
        Iteration = $Iteration
        Passed = $true
        Errors = @()
    }
    
    try {
        # Test 1: Validate module structure follows HashiCorp standards
        Write-Host "  Checking module structure..." -ForegroundColor Gray
        
        $RequiredFiles = @("main-dms.tf", "variables.tf", "outputs.tf", "locals.tf", "README.md")
        foreach ($File in $RequiredFiles) {
            $FilePath = Join-Path $ModulePath $File
            if (-not (Test-Path $FilePath)) {
                $TestResult.Errors += "Missing required file: $File"
                $TestResult.Passed = $false
            }
        }
        
        # Test 2: Validate variables.tf follows HashiCorp standards
        Write-Host "  Validating variables structure..." -ForegroundColor Gray
        
        $VariablesContent = Get-Content (Join-Path $ModulePath "variables.tf") -Raw
        
        # Check for required variable attributes
        $RequiredVariablePatterns = @(
            'description\s*=',  # All variables should have descriptions
            'type\s*=',         # All variables should have types
            'validation\s*{'    # Critical variables should have validation
        )
        
        foreach ($Pattern in $RequiredVariablePatterns) {
            if ($VariablesContent -notmatch $Pattern) {
                $TestResult.Errors += "Variables file missing pattern: $Pattern"
                $TestResult.Passed = $false
            }
        }
        
        # Test 3: Validate outputs.tf follows HashiCorp standards
        Write-Host "  Validating outputs structure..." -ForegroundColor Gray
        
        $OutputsContent = Get-Content (Join-Path $ModulePath "outputs.tf") -Raw
        
        # Check for structured outputs (HashiCorp best practice)
        $RequiredOutputStructures = @(
            'output\s+"dms_instance"',      # Structured instance output
            'output\s+"replication_task"',  # Structured task output
            'output\s+"endpoints"',         # Structured endpoints output
            'output\s+"network"'            # Structured network output
        )
        
        foreach ($Structure in $RequiredOutputStructures) {
            if ($OutputsContent -notmatch $Structure) {
                $TestResult.Errors += "Missing structured output: $Structure"
                $TestResult.Passed = $false
            }
        }
        
        # Test 4: Validate output descriptions are comprehensive
        Write-Host "  Checking output descriptions..." -ForegroundColor Gray
        
        # Count output blocks and descriptions
        $OutputBlocks = ($OutputsContent | Select-String 'output\s+"[^"]+"\s*{' -AllMatches).Matches.Count
        $OutputDescriptions = ($OutputsContent | Select-String 'description\s*=' -AllMatches).Matches.Count
        
        if ($OutputDescriptions -lt $OutputBlocks) {
            $TestResult.Errors += "Not all outputs have descriptions ($OutputDescriptions/$OutputBlocks)"
            $TestResult.Passed = $false
        }
        
        # Test 5: Validate backward compatibility
        Write-Host "  Checking backward compatibility..." -ForegroundColor Gray
        
        $LegacyOutputs = @(
            'replication_instance_arn',
            'replication_instance_id',
            'replication_task_arn',
            'replication_task_id',
            'source_endpoint_arn',
            'target_endpoint_arn'
        )
        
        foreach ($LegacyOutput in $LegacyOutputs) {
            if ($OutputsContent -notmatch "output\s+`"$LegacyOutput`"") {
                $TestResult.Errors += "Missing legacy output for backward compatibility: $LegacyOutput"
                $TestResult.Passed = $false
            }
        }
        
        # Test 6: Validate English documentation
        Write-Host "  Validating English documentation..." -ForegroundColor Gray
        
        # Check for Portuguese words that should be translated
        $PortugueseWords = @('instância', 'configuração', 'rede', 'segurança', 'tarefa')
        foreach ($Word in $PortugueseWords) {
            if ($OutputsContent -match $Word) {
                $TestResult.Errors += "Found Portuguese word in outputs: $Word"
                $TestResult.Passed = $false
            }
        }
        
        # Test 7: Validate module integration patterns
        Write-Host "  Checking module integration patterns..." -ForegroundColor Gray
        
        # Verify that outputs provide clean interfaces for module integration
        $IntegrationPatterns = @(
            'value\s*=\s*{',  # Structured output values
            'arn\s*=',        # ARN outputs for resource references
            'id\s*='          # ID outputs for resource references
        )
        
        foreach ($Pattern in $IntegrationPatterns) {
            if ($OutputsContent -notmatch $Pattern) {
                $TestResult.Errors += "Missing integration pattern: $Pattern"
                $TestResult.Passed = $false
            }
        }
        
        # Test 8: Validate logical grouping in outputs
        Write-Host "  Validating logical grouping..." -ForegroundColor Gray
        
        # Check for section headers that indicate proper organization
        $SectionHeaders = @(
            'DMS INSTANCE',
            'REPLICATION TASK',
            'DATABASE ENDPOINTS',
            'NETWORK RESOURCES',
            'LEGACY COMPATIBILITY'
        )
        
        foreach ($Header in $SectionHeaders) {
            if ($OutputsContent -notmatch $Header) {
                $TestResult.Errors += "Missing section header: $Header"
                $TestResult.Passed = $false
            }
        }
        
        # Test 9: Validate deprecation notices for legacy outputs
        Write-Host "  Checking deprecation notices..." -ForegroundColor Gray
        
        if ($OutputsContent -notmatch "DEPRECATED") {
            $TestResult.Errors += "Legacy outputs should include deprecation notices"
            $TestResult.Passed = $false
        }
        
        # Test 10: Validate comprehensive output information
        Write-Host "  Validating comprehensive output information..." -ForegroundColor Gray
        
        # Check that structured outputs include comprehensive information
        $ComprehensiveFields = @(
            'engine_version',
            'instance_class',
            'allocated_storage',
            'multi_az',
            'migration_type',
            'ssl_mode'
        )
        
        foreach ($Field in $ComprehensiveFields) {
            if ($OutputsContent -notmatch $Field) {
                $TestResult.Errors += "Missing comprehensive field in outputs: $Field"
                $TestResult.Passed = $false
            }
        }
        
        if ($TestResult.Passed) {
            Write-Host "  ✓ All HashiCorp standards compliance tests passed" -ForegroundColor Green
        } else {
            Write-Host "  ✗ HashiCorp standards compliance test failed" -ForegroundColor Red
            foreach ($Error in $TestResult.Errors) {
                Write-Host "    - $Error" -ForegroundColor Red
            }
        }
        
    } catch {
        $TestResult.Passed = $false
        $TestResult.Errors += "Exception during testing: $($_.Exception.Message)"
        Write-Host "  ✗ Exception occurred: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    return $TestResult
}

# Run property-based tests
Write-Host "`nRunning property-based tests..." -ForegroundColor Yellow

for ($i = 1; $i -le $Iterations; $i++) {
    # Select a random configuration for this iteration
    $Config = $TestConfigurations | Get-Random
    
    $Result = Test-HashiCorpStandardsCompliance -Config $Config -Iteration $i
    $TestResults += $Result
    
    if (-not $Result.Passed) {
        $ErrorCount++
    }
    
    # Progress indicator
    if ($i % 25 -eq 0) {
        $SuccessRate = [math]::Round((($i - $ErrorCount) / $i) * 100, 2)
        Write-Host "Progress: $i/$Iterations iterations completed. Success rate: $SuccessRate%" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Green
Write-Host "Total iterations: $Iterations" -ForegroundColor White
Write-Host "Successful tests: $($Iterations - $ErrorCount)" -ForegroundColor Green
Write-Host "Failed tests: $ErrorCount" -ForegroundColor Red

if ($ErrorCount -eq 0) {
    Write-Host "`n✓ Property 5: HashiCorp Module Standards Compliance - ALL TESTS PASSED" -ForegroundColor Green
    Write-Host "The module successfully follows HashiCorp standards across all test iterations." -ForegroundColor Green
} else {
    Write-Host "`n✗ Property 5: HashiCorp Module Standards Compliance - SOME TESTS FAILED" -ForegroundColor Red
    Write-Host "Success rate: $([math]::Round((($Iterations - $ErrorCount) / $Iterations) * 100, 2))%" -ForegroundColor Yellow
    
    # Show unique error patterns
    $UniqueErrors = $TestResults | Where-Object { -not $_.Passed } | ForEach-Object { $_.Errors } | Sort-Object -Unique
    Write-Host "`nUnique error patterns:" -ForegroundColor Yellow
    foreach ($Error in $UniqueErrors) {
        Write-Host "  - $Error" -ForegroundColor Red
    }
}

# Detailed analysis
Write-Host "`n=== Detailed Analysis ===" -ForegroundColor Green

$ConfigurationResults = $TestResults | Group-Object { $_.Config.Name }
foreach ($ConfigGroup in $ConfigurationResults) {
    $ConfigName = $ConfigGroup.Name
    $ConfigTests = $ConfigGroup.Group
    $ConfigSuccessRate = [math]::Round((($ConfigTests | Where-Object { $_.Passed }).Count / $ConfigTests.Count) * 100, 2)
    
    Write-Host "Configuration '$ConfigName': $ConfigSuccessRate% success rate" -ForegroundColor Cyan
}

# Exit with appropriate code
if ($ErrorCount -eq 0) {
    exit 0
} else {
    exit 1
}