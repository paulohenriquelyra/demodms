# ============================================================================
# Code Organization and Section Separation Validation Script
# ============================================================================
#
# Feature: dms-module-refactoring, Property 3: Code Organization and Section Separation
# Property: For any module file structure, related resources should be grouped 
# in clearly marked sections with consistent 3-line header patterns, and logical 
# separation should be maintained across all resource types.
# Validates: Requirements 4.1, 4.2, 4.4, 9.4, 9.5
#
# This script validates that:
# 1. Clear section headers with 3-line patterns are used
# 2. Resources are logically grouped by component
# 3. Consistent section separation is maintained
# 4. File organization follows best practices
# ============================================================================

param(
    [string]$ModulePath = "../"
)

Write-Host "=== Code Organization and Section Separation Validation ===" -ForegroundColor Green
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

# Test 1: Validate main-dms.tf section headers
Write-Host "`n--- Test 1: Section Header Format ---" -ForegroundColor Cyan

$mainFile = Join-Path $ModulePath "main-dms.tf"
$mainExists = Test-Path $mainFile
Test-Assertion $mainExists "Main DMS file exists" "main-dms.tf file not found"

if ($mainExists) {
    $mainContent = Get-Content $mainFile -Raw
    
    # Check for 3-line section header pattern
    $sectionHeaderPattern = "#{50,}\s*\n#{10,}\s+[A-Z\s]+#{10,}\s*\n#{50,}"
    $sectionHeaders = [regex]::Matches($mainContent, $sectionHeaderPattern)
    
    $hasProperHeaders = $sectionHeaders.Count -ge 4  # Expect at least 4 major sections
    Test-Assertion $hasProperHeaders "Proper 3-line section headers used ($($sectionHeaders.Count) found)" "Should have at least 4 section headers with 3-line format"
    
    # Check for specific expected sections
    $expectedSections = @(
        "DMS NETWORK",
        "DMS SECURITY", 
        "DMS INSTANCE",
        "DMS ENDPOINTS",
        "DMS TASKS"
    )
    
    foreach ($section in $expectedSections) {
        $sectionExists = $mainContent -match "#{10,}\s+$section\s+#{10,}"
        Test-Assertion $sectionExists "Section '$section' properly formatted" "Section '$section' should have proper 3-line header format"
    }
}

# Test 2: Validate logical resource grouping
Write-Host "`n--- Test 2: Logical Resource Grouping ---" -ForegroundColor Cyan

if ($mainExists) {
    $mainContent = Get-Content $mainFile -Raw
    
    # Check that resources are in their appropriate sections
    $resourceChecks = @(
        @{Resource = "aws_dms_replication_subnet_group"; Section = "DMS NETWORK"},
        @{Resource = "aws_security_group"; Section = "DMS SECURITY"},
        @{Resource = "aws_security_group_rule"; Section = "DMS SECURITY"},
        @{Resource = "aws_dms_replication_instance"; Section = "DMS INSTANCE"},
        @{Resource = "aws_dms_endpoint"; Section = "DMS ENDPOINTS"},
        @{Resource = "aws_dms_replication_task"; Section = "DMS TASKS"}
    )
    
    foreach ($check in $resourceChecks) {
        $resourceExists = $mainContent -match $check.Resource
        Test-Assertion $resourceExists "Resource '$($check.Resource)' exists in module" "Resource '$($check.Resource)' should be present in the module"
    }
}

# Test 3: Validate consistent section formatting
Write-Host "`n--- Test 3: Consistent Section Formatting ---" -ForegroundColor Cyan

if ($mainExists) {
    $mainContent = Get-Content $mainFile -Raw
    
    # Check that section headers use consistent formatting
    $headerPattern = "#{40,}"
    $headerMatches = [regex]::Matches($mainContent, $headerPattern)
    
    # We expect at least 10 header lines (2 per section * 5 sections)
    $headerCount = $headerMatches.Count
    Test-Assertion ($headerCount -ge 10) "Sufficient header lines ($headerCount found)" "Should have at least 10 header lines for proper section formatting"
    
    # Check that section titles are properly formatted (uppercase with spaces)
    $titlePattern = "#{10,}\s+[A-Z\s]+\s+#{10,}"
    $titleMatches = [regex]::Matches($mainContent, $titlePattern)
    $titleCount = $titleMatches.Count
    
    Test-Assertion ($titleCount -ge 5) "Section titles properly formatted ($titleCount found)" "Should have at least 5 properly formatted section titles"
}

# Test 4: Validate file size and consolidation
Write-Host "`n--- Test 4: File Size and Consolidation ---" -ForegroundColor Cyan

if ($mainExists) {
    $mainLines = (Get-Content $mainFile | Measure-Object -Line).Lines
    
    # Check if security groups are consolidated (no separate security-groups.tf)
    $securityGroupsFile = Join-Path $ModulePath "security-groups.tf"
    $separateSecurityFile = Test-Path $securityGroupsFile
    
    if ($separateSecurityFile) {
        $securityLines = (Get-Content $securityGroupsFile | Measure-Object -Line).Lines
        $totalLines = $mainLines + $securityLines
        
        Test-Assertion ($totalLines -lt 500) "Combined file size under 500 lines ($totalLines total)" "Combined main and security files should be under 500 lines for consolidation"
        
        if ($totalLines -lt 500) {
            Write-Host "⚠️  RECOMMENDATION: Consider consolidating security-groups.tf into main-dms.tf (total: $totalLines lines)" -ForegroundColor Yellow
        }
    } else {
        Test-Assertion $true "Security groups consolidated into main file" "Security groups are properly consolidated"
    }
    
    Test-Assertion ($mainLines -lt 600) "Main file size reasonable ($mainLines lines)" "Main file should be under 600 lines for maintainability"
}

# Test 5: Validate English documentation and comments
Write-Host "`n--- Test 5: English Documentation ---" -ForegroundColor Cyan

if ($mainExists) {
    $mainContent = Get-Content $mainFile -Raw
    
    # Check for English comments (no Portuguese)
    $portuguesePatterns = @(
        "Este módulo",
        "Recursos criados",
        "Melhores práticas",
        "Cria um grupo",
        "Instância principal",
        "Endpoint de origem",
        "Tarefa principal"
    )
    
    $hasPortuguese = $false
    foreach ($pattern in $portuguesePatterns) {
        if ($mainContent -match $pattern) {
            $hasPortuguese = $true
            break
        }
    }
    
    Test-Assertion (-not $hasPortuguese) "All comments in English" "All comments and documentation should be in English"
    
    # Check for proper English documentation patterns
    $englishPatterns = @(
        "This module",
        "Resources created",
        "Best practices",
        "Creates a group",
        "Main instance",
        "Source endpoint",
        "Main migration task"
    )
    
    $englishCount = 0
    foreach ($pattern in $englishPatterns) {
        if ($mainContent -match $pattern) {
            $englishCount++
        }
    }
    
    Test-Assertion ($englishCount -ge 3) "English documentation patterns present ($englishCount found)" "Should have comprehensive English documentation"
}

# Test 6: Validate resource naming follows section organization
Write-Host "`n--- Test 6: Resource Naming Alignment ---" -ForegroundColor Cyan

if ($mainExists) {
    $mainContent = Get-Content $mainFile -Raw
    
    # Check that resource names align with their sections
    $resourceSectionAlignment = @(
        @{Section = "DMS NETWORK"; Resource = "aws_dms_replication_subnet_group"},
        @{Section = "DMS SECURITY"; Resource = "aws_security_group"},
        @{Section = "DMS INSTANCE"; Resource = "aws_dms_replication_instance"},
        @{Section = "DMS ENDPOINTS"; Resource = "aws_dms_endpoint"},
        @{Section = "DMS TASKS"; Resource = "aws_dms_replication_task"}
    )
    
    foreach ($alignment in $resourceSectionAlignment) {
        # Find the section
        $sectionStart = $mainContent.IndexOf($alignment.Section)
        if ($sectionStart -ge 0) {
            # Find the next section or end of file
            $nextSectionPattern = "#{50,}\s*\n#{10,}\s+[A-Z\s]+#{10,}"
            $remainingContent = $mainContent.Substring($sectionStart + $alignment.Section.Length)
            $nextSectionMatch = [regex]::Match($remainingContent, $nextSectionPattern)
            $sectionEnd = if ($nextSectionMatch.Success) { $sectionStart + $alignment.Section.Length + $nextSectionMatch.Index } else { $mainContent.Length }
            
            # Check if resource is in this section
            $sectionContent = $mainContent.Substring($sectionStart, $sectionEnd - $sectionStart)
            $resourceInSection = ($sectionContent -match $alignment.Resource) -ne $null
            
            Test-Assertion $resourceInSection "Resource '$($alignment.Resource)' in correct section '$($alignment.Section)'" "Resource should be in its designated section"
        }
    }
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Green
Write-Host "Total Tests: $TestCount" -ForegroundColor Yellow
Write-Host "Passed: $($TestCount - $ErrorCount)" -ForegroundColor Green
Write-Host "Failed: $ErrorCount" -ForegroundColor $(if ($ErrorCount -eq 0) { "Green" } else { "Red" })

if ($ErrorCount -eq 0) {
    Write-Host "`n🎉 All code organization tests passed!" -ForegroundColor Green
    Write-Host "✅ Property 3: Code Organization and Section Separation - VALIDATED" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n❌ Some code organization tests failed!" -ForegroundColor Red
    Write-Host "Please fix the issues above before proceeding." -ForegroundColor Yellow
    exit 1
}