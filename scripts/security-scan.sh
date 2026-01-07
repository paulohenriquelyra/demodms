#!/bin/bash

# Script de Security Scan Local
# Executa as mesmas verificações do pipeline CI/CD

set -e

echo "🔒 Iniciando Security Scan Local..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Verificar se checkov está instalado
if ! command -v /home/paulofl/.local/bin/checkov &> /dev/null; then
    error "Checkov não encontrado. Instale com: pip install checkov"
    exit 1
fi

# Criar diretório para relatórios
mkdir -p reports

log "1. Configurando variáveis de ambiente para teste..."
# Definir variáveis de ambiente necessárias para validação
export PROJECT_NAME="dms-security-test"
export ENVIRONMENT="development"
export OWNER="security-team"
export COST_CENTER="testing"
export AWS_REGION="us-east-1"
export VPC_ID="vpc-0123456789abcdef0"
export SUBNET_ID_1="subnet-0123456789abcdef0"
export SUBNET_ID_2="subnet-0fedcba9876543210"
export SOURCE_ENGINE="mysql"
export SOURCE_DB_HOST="test-source.example.com"
export SOURCE_DB_PORT="3306"
export SOURCE_DB_NAME="test_db"
export TARGET_ENGINE="postgres"
export TARGET_DB_HOST="test-target.example.com"
export TARGET_DB_PORT="5432"
export TARGET_DB_NAME="test_db"
export USE_SECRETS_MANAGER="false"
export SOURCE_DB_USERNAME="test_user"
export SOURCE_DB_PASSWORD="test_password"
export TARGET_DB_USERNAME="test_user"
export TARGET_DB_PASSWORD="test_password"
export SOURCE_SECURITY_GROUP_ID="sg-0123456789abcdef0"
export TARGET_SECURITY_GROUP_ID="sg-0fedcba9876543210"
export KMS_KEY_ARN="arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
export MIGRATION_TYPE="full-load-and-cdc"
export SOURCE_SCHEMA_NAME="%"
export SOURCE_TABLE_PATTERN="%"
export TARGET_SCHEMA_NAME="public"
export DMS_ENGINE_VERSION="3.5.2"
export MAINTENANCE_WINDOW="sun:03:00-sun:04:00"

log "2. Gerando main.tf a partir do template..."
# Função para substituir variáveis no template
substitute_template() {
    local template_file="main.tf"
    local output_file="main.tf.generated"
    
    # Fazer backup do main.tf original
    cp "$template_file" "${template_file}.backup"
    
    # Substituir todas as variáveis {{VAR}} pelos valores das variáveis de ambiente
    sed_script=""
    for var in PROJECT_NAME ENVIRONMENT OWNER COST_CENTER AWS_REGION VPC_ID SUBNET_ID_1 SUBNET_ID_2 \
               SOURCE_ENGINE SOURCE_DB_HOST SOURCE_DB_PORT SOURCE_DB_NAME TARGET_ENGINE TARGET_DB_HOST \
               TARGET_DB_PORT TARGET_DB_NAME USE_SECRETS_MANAGER SOURCE_DB_USERNAME SOURCE_DB_PASSWORD \
               TARGET_DB_USERNAME TARGET_DB_PASSWORD SOURCE_SECURITY_GROUP_ID TARGET_SECURITY_GROUP_ID \
               KMS_KEY_ARN MIGRATION_TYPE SOURCE_SCHEMA_NAME SOURCE_TABLE_PATTERN TARGET_SCHEMA_NAME \
               DMS_ENGINE_VERSION MAINTENANCE_WINDOW SOURCE_SECRETS_ARN SOURCE_SECRETS_ROLE_ARN \
               TARGET_SECRETS_ARN TARGET_SECRETS_ROLE_ARN; do
        value="${!var}"
        sed_script="${sed_script}s|{{${var}}}|${value}|g;"
    done
    
    sed "$sed_script" "$template_file" > "$output_file"
    mv "$output_file" "$template_file"
}

# Gerar main.tf a partir do template
substitute_template
success "main.tf processado com substituição de variáveis"

log "3. Executando Terraform validate..."
if terraform validate; then
    success "Terraform validate passou"
else
    error "Terraform validate falhou"
    exit 1
fi

log "2. Verificando formatação Terraform..."
if terraform fmt -check -recursive; then
    success "Formatação Terraform está correta"
else
    warning "Formatação Terraform precisa de correção. Execute: terraform fmt -recursive"
fi

log "3. Executando Checkov Security Scan..."
/home/paulofl/.local/bin/checkov -d . \
    --config-file .checkov.yml \
    --framework terraform \
    --output cli \
    --output json \
    --output sarif \
    --output-file-path console,reports/checkov-report.json,reports/checkov-report.sarif \
    --soft-fail \
    --compact

# Verificar resultados
if [ -f "reports/checkov-report.json" ]; then
    # Contar issues por severidade
    HIGH_ISSUES=$(jq '[.results.failed_checks[] | select(.severity == "HIGH")] | length' reports/checkov-report.json 2>/dev/null || echo "0")
    MEDIUM_ISSUES=$(jq '[.results.failed_checks[] | select(.severity == "MEDIUM")] | length' reports/checkov-report.json 2>/dev/null || echo "0")
    LOW_ISSUES=$(jq '[.results.failed_checks[] | select(.severity == "LOW")] | length' reports/checkov-report.json 2>/dev/null || echo "0")
    
    echo ""
    echo "📊 Resumo do Security Scan:"
    echo "   🔴 HIGH: $HIGH_ISSUES issues"
    echo "   🟡 MEDIUM: $MEDIUM_ISSUES issues"
    echo "   🟢 LOW: $LOW_ISSUES issues"
    echo ""
    
    if [ "$HIGH_ISSUES" -gt 0 ]; then
        error "Encontrados $HIGH_ISSUES issues de alta severidade!"
        echo "Revise o relatório em: reports/checkov-report.json"
        exit 1
    elif [ "$MEDIUM_ISSUES" -gt 5 ]; then
        warning "Encontrados $MEDIUM_ISSUES issues de média severidade. Considere revisar."
    fi
fi

log "4. Executando testes adicionais de segurança..."

# Verificar se há credenciais hardcoded (apenas diretório raiz e modules/dms)
log "   Verificando credenciais hardcoded..."
if find . -maxdepth 1 -name "*.tf" -o -name "*.tfvars" -o -path "./modules/dms/*.tf" | \
   xargs grep -l -i "password\|secret\|key" | \
   xargs grep -i "password\|secret\|key" | \
   grep -v "variable\|description\|#\|template\|arn:aws:\|secrets_manager\|kms_key" | \
   grep -v "test_password\|test_user\|{{.*}}\|== \"true\"" | \
   grep -E "(password|secret|key)\s*=\s*\"[^\"]+\"" > /dev/null; then
    error "Credenciais hardcoded reais encontradas!"
    exit 1
else
    success "Nenhuma credencial hardcoded real encontrada"
fi

# Verificar tags obrigatórias (apenas diretório raiz e modules/dms)
log "   Verificando tags obrigatórias..."
REQUIRED_TAGS=("Environment" "Project" "Owner" "Terraform")
for tag in "${REQUIRED_TAGS[@]}"; do
    if ! find . -maxdepth 1 -name "*.tf" -o -path "./modules/dms/*.tf" | \
       xargs grep -l "\"$tag\"" > /dev/null 2>&1; then
        warning "Tag obrigatória '$tag' pode estar faltando em alguns recursos"
    fi
done

log "5. Gerando relatório final..."
cat > reports/security-summary.md << EOF
# Security Scan Report

**Data:** $(date)
**Commit:** $(git rev-parse HEAD 2>/dev/null || echo "N/A")

## Resumo
- 🔴 HIGH: $HIGH_ISSUES issues
- 🟡 MEDIUM: $MEDIUM_ISSUES issues  
- 🟢 LOW: $LOW_ISSUES issues

## Arquivos Verificados
$(find . -maxdepth 1 -name "*.tf" | wc -l) arquivos Terraform no diretório raiz
$(find ./modules/dms -name "*.tf" 2>/dev/null | wc -l) arquivos Terraform no módulo DMS

## Próximos Passos
1. Revisar issues de alta severidade
2. Corrigir formatação se necessário
3. Validar tags obrigatórias
4. Executar testes antes do commit

## Relatórios Detalhados
- JSON: reports/checkov-report.json
- SARIF: reports/checkov-report.sarif
EOF

success "Security scan concluído!"
echo "📋 Relatório salvo em: reports/security-summary.md"

# Abrir relatório se possível
if command -v code &> /dev/null; then
    log "Abrindo relatório no VS Code..."
    code reports/security-summary.md
fi