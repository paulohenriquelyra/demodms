#!/bin/bash
# ============================================================================
# Quick Test Script - AWS DMS Implementation
# ============================================================================
#
# Este script executa testes rápidos e gratuitos para validar a implementação
# sem criar recursos AWS reais.
#
# Usage: ./scripts/quick-test.sh
#
# Features:
# ✅ Validação de sintaxe Terraform
# ✅ Validação de scripts bash
# ✅ Teste de substituição de template
# ✅ Validação de plano Terraform
# ✅ Sem custos AWS
# ============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TEST_ENV_FILE="$PROJECT_DIR/test-vars.env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Logging functions
log_test() {
    echo -e "${BLUE}🧪 $1${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

log_header() {
    echo -e "${BOLD}${CYAN}$1${NC}"
    echo -e "${CYAN}$(printf '=%.0s' {1..60})${NC}"
}

# Create test environment variables
create_test_env() {
    log_info "Criando variáveis de ambiente de teste..."
    
    cat > "$TEST_ENV_FILE" << 'EOF'
export PROJECT_NAME="test-dms-project"
export ENVIRONMENT="development"
export VPC_ID="vpc-0123456789abcdef0"
export SUBNET_ID_1="subnet-0123456789abcdef0"
export SUBNET_ID_2="subnet-0fedcba9876543210"
export SOURCE_SECURITY_GROUP_ID="sg-0123456789abcdef0"
export TARGET_SECURITY_GROUP_ID="sg-0fedcba9876543210"
export KMS_KEY_ARN="arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
export SOURCE_ENGINE="mysql"
export SOURCE_DB_HOST="test-source.example.com"
export SOURCE_DB_PORT="3306"
export SOURCE_DB_NAME="test_source"
export TARGET_ENGINE="postgres"
export TARGET_DB_HOST="test-target.example.com"
export TARGET_DB_PORT="5432"
export TARGET_DB_NAME="test_target"
export USE_SECRETS_MANAGER="false"
export SOURCE_DB_USERNAME="test_user"
export SOURCE_DB_PASSWORD="test_password"
export TARGET_DB_USERNAME="test_user"
export TARGET_DB_PASSWORD="test_password"
export MIGRATION_TYPE="full-load-and-cdc"
export SOURCE_SCHEMA_NAME="%"
export SOURCE_TABLE_PATTERN="%"
export TARGET_SCHEMA_NAME="public"
export DMS_ENGINE_VERSION="3.5.2"
export MAINTENANCE_WINDOW="sun:03:00-sun:04:00"
export OWNER="test-team"
export COST_CENTER="testing"
export SOURCE_SSL_MODE="prefer"
export TARGET_SSL_MODE="prefer"
export SOURCE_EXTRA_ATTRIBUTES=""
export TARGET_EXTRA_ATTRIBUTES=""
export ENFORCE_SSL="true"
export REQUIRE_KMS="true"
EOF
    
    log_success "Variáveis de teste criadas em $TEST_ENV_FILE"
}

# Test 1: Terraform syntax validation
test_terraform_syntax() {
    log_test "Teste 1: Validação de sintaxe Terraform"
    
    cd "$PROJECT_DIR"
    
    # Check if terraform is available
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform não encontrado. Instale o Terraform para executar este teste."
        return 1
    fi
    
    # Test terraform fmt
    if terraform fmt -check > /dev/null 2>&1; then
        log_success "Formatação Terraform correta"
    else
        log_warning "Formatação Terraform pode ser melhorada (execute: terraform fmt)"
    fi
    
    # Test terraform validate (without backend)
    if terraform init -backend=false > /dev/null 2>&1; then
        if terraform validate > /dev/null 2>&1; then
            log_success "Sintaxe Terraform válida"
        else
            log_error "Erro de sintaxe Terraform"
            terraform validate
            return 1
        fi
    else
        log_error "Falha ao inicializar Terraform"
        return 1
    fi
}

# Test 2: Bash scripts validation
test_bash_scripts() {
    log_test "Teste 2: Validação de scripts bash"
    
    local scripts=(
        "scripts/deploy-cicd.sh"
        "scripts/dms-operations.sh"
        "scripts/start-dms.sh"
        "scripts/stop-dms.sh"
        "scripts/monitor-dms.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$PROJECT_DIR/$script" ]; then
            if bash -n "$PROJECT_DIR/$script" 2>/dev/null; then
                log_success "$(basename "$script") - sintaxe válida"
            else
                log_error "$(basename "$script") - erro de sintaxe"
                bash -n "$PROJECT_DIR/$script"
                return 1
            fi
        else
            log_warning "$(basename "$script") - arquivo não encontrado"
        fi
    done
}

# Test 3: Script help functions
test_script_help() {
    log_test "Teste 3: Funções de ajuda dos scripts"
    
    local scripts=(
        "scripts/deploy-cicd.sh"
        "scripts/dms-operations.sh"
        "scripts/start-dms.sh"
        "scripts/stop-dms.sh"
        "scripts/monitor-dms.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$PROJECT_DIR/$script" ] && [ -x "$PROJECT_DIR/$script" ]; then
            if "$PROJECT_DIR/$script" --help > /dev/null 2>&1; then
                log_success "$(basename "$script") - função --help funcionando"
            else
                log_warning "$(basename "$script") - função --help pode ter problemas"
            fi
        else
            log_warning "$(basename "$script") - não executável ou não encontrado"
        fi
    done
}

# Test 4: Template substitution
test_template_substitution() {
    log_test "Teste 4: Substituição de template"
    
    cd "$PROJECT_DIR"
    
    # Load test environment
    if [ -f "$TEST_ENV_FILE" ]; then
        source "$TEST_ENV_FILE"
    else
        log_error "Arquivo de variáveis de teste não encontrado"
        return 1
    fi
    
    # Test dry-run mode
    if [ -x "scripts/deploy-cicd.sh" ]; then
        if scripts/deploy-cicd.sh development --dry-run > /dev/null 2>&1; then
            log_success "Script deploy-cicd.sh --dry-run funcionando"
        else
            log_error "Falha no deploy-cicd.sh --dry-run"
            return 1
        fi
    else
        log_error "Script deploy-cicd.sh não encontrado ou não executável"
        return 1
    fi
    
    # Test validate mode
    if scripts/deploy-cicd.sh development --validate > /dev/null 2>&1; then
        log_success "Script deploy-cicd.sh --validate funcionando"
        
        # Check if template variables were substituted
        if [ -f "main.tf" ]; then
            local remaining_vars=$(grep -c "{{" main.tf 2>/dev/null || echo "0")
            if [ "$remaining_vars" -eq 0 ]; then
                log_success "Todas as variáveis de template foram substituídas"
            else
                log_warning "$remaining_vars variáveis de template não substituídas"
                grep -n "{{" main.tf || true
            fi
        else
            log_error "main.tf não foi gerado"
            return 1
        fi
    else
        log_error "Falha no deploy-cicd.sh --validate"
        return 1
    fi
}

# Test 5: Terraform plan validation
test_terraform_plan() {
    log_test "Teste 5: Validação do plano Terraform"
    
    cd "$PROJECT_DIR"
    
    if [ ! -f "main.tf" ]; then
        log_error "main.tf não encontrado. Execute o teste de substituição primeiro."
        return 1
    fi
    
    # Initialize terraform
    if terraform init -backend=false > /dev/null 2>&1; then
        log_success "Terraform inicializado com sucesso"
    else
        log_error "Falha ao inicializar Terraform"
        return 1
    fi
    
    # Validate configuration
    if terraform validate > /dev/null 2>&1; then
        log_success "Configuração Terraform válida"
    else
        log_error "Configuração Terraform inválida"
        terraform validate
        return 1
    fi
    
    # Create plan (this will fail due to fake resources, but should validate syntax)
    log_info "Criando plano Terraform (esperado falhar devido a recursos fictícios)..."
    if terraform plan -out=test.tfplan > /dev/null 2>&1; then
        log_success "Plano Terraform criado com sucesso"
        
        # Analyze plan
        local resource_count=$(terraform show -json test.tfplan 2>/dev/null | jq '.planned_values.root_module.resources | length' 2>/dev/null || echo "unknown")
        log_info "Recursos planejados: $resource_count"
        
        # Clean up
        rm -f test.tfplan
    else
        log_warning "Plano Terraform falhou (esperado com recursos fictícios)"
        log_info "Isso é normal - os recursos AWS fictícios não existem"
    fi
}

# Test 6: Output validation
test_outputs() {
    log_test "Teste 6: Validação de outputs"
    
    cd "$PROJECT_DIR"
    
    if [ -f "outputs.tf" ]; then
        # Check if outputs.tf has valid syntax
        if terraform validate > /dev/null 2>&1; then
            log_success "outputs.tf tem sintaxe válida"
        else
            log_error "outputs.tf tem erro de sintaxe"
            return 1
        fi
        
        # Check for CLI commands output
        if grep -q "cli_commands" outputs.tf; then
            log_success "Output cli_commands encontrado"
        else
            log_warning "Output cli_commands não encontrado"
        fi
        
        # Check for operational guide output
        if grep -q "operational_guide" outputs.tf; then
            log_success "Output operational_guide encontrado"
        else
            log_warning "Output operational_guide não encontrado"
        fi
    else
        log_error "outputs.tf não encontrado"
        return 1
    fi
}

# Cleanup function
cleanup() {
    log_info "Limpando arquivos temporários..."
    cd "$PROJECT_DIR"
    
    # Remove test files
    rm -f test.tfplan
    rm -f .terraform.lock.hcl
    rm -rf .terraform/
    rm -f "$TEST_ENV_FILE"
    
    # Restore original main.tf if it was modified
    if [ -f "old/main.tf" ] && [ ! -f "main-original.tf" ]; then
        log_info "Mantendo main.tf gerado para inspeção"
        log_info "Para restaurar: cp old/main.tf main.tf"
    fi
    
    log_success "Limpeza concluída"
}

# Main test execution
main() {
    log_header "🧪 TESTE RÁPIDO - AWS DMS IMPLEMENTATION"
    echo
    log_info "Este teste valida a implementação sem criar recursos AWS reais"
    log_info "Duração estimada: 2-3 minutos"
    echo
    
    # Create test environment
    create_test_env
    echo
    
    # Run tests
    test_terraform_syntax
    echo
    
    test_bash_scripts
    echo
    
    test_script_help
    echo
    
    test_template_substitution
    echo
    
    test_terraform_plan
    echo
    
    test_outputs
    echo
    
    # Show results
    log_header "📊 RESULTADOS DOS TESTES"
    echo
    log_info "Total de testes: $TOTAL_TESTS"
    log_success "Testes aprovados: $TESTS_PASSED"
    
    if [ $TESTS_FAILED -gt 0 ]; then
        log_error "Testes falharam: $TESTS_FAILED"
        echo
        log_warning "Alguns testes falharam. Verifique os erros acima."
        echo
        log_info "Para mais detalhes, consulte o arquivo TESTING.md"
    else
        echo
        log_success "🎉 TODOS OS TESTES PASSARAM!"
        echo
        log_info "A implementação está pronta para uso!"
        echo
        log_info "Próximos passos:"
        echo "  1. Configure suas variáveis AWS reais"
        echo "  2. Execute: ./scripts/deploy-cicd.sh production --dry-run"
        echo "  3. Para deploy real: ./scripts/deploy-cicd.sh production"
    fi
    
    echo
    log_info "Para testes mais avançados, consulte: TESTING.md"
    
    # Cleanup
    cleanup
    
    # Exit with appropriate code
    if [ $TESTS_FAILED -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n\n${YELLOW}Teste interrompido pelo usuário${NC}"; cleanup; exit 130' INT

# Run main function
main "$@"