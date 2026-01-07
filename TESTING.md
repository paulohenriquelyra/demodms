# Guia de Testes - AWS DMS Deployment

Este guia fornece várias estratégias para testar a implementação DMS, desde validação básica até testes completos.

## 🧪 Níveis de Teste

### 1. **Validação de Sintaxe** (Sem custos AWS)
### 2. **Validação de Template** (Sem custos AWS)
### 3. **Teste de Plano Terraform** (Sem custos AWS)
### 4. **Teste com Recursos Mínimos** (Custo baixo)
### 5. **Teste Completo** (Custo real)

---

## 🔍 1. Validação de Sintaxe

### Validar Terraform
```bash
# Validar sintaxe do main.tf
terraform validate

# Verificar formatação
terraform fmt -check

# Validar com backend local
terraform init -backend=false
terraform validate
```

### Validar Scripts
```bash
# Verificar sintaxe dos scripts bash
bash -n scripts/deploy-cicd.sh
bash -n scripts/dms-operations.sh
bash -n scripts/start-dms.sh
bash -n scripts/stop-dms.sh
bash -n scripts/monitor-dms.sh

# Executar com --help para verificar funcionamento
./scripts/deploy-cicd.sh --help
./scripts/dms-operations.sh --help
```

---

## 📝 2. Validação de Template

### Testar Substituição de Variáveis
```bash
# Criar arquivo de teste com variáveis de exemplo
cat > test-vars.env << 'EOF'
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
EOF

# Carregar variáveis de teste
source test-vars.env

# Testar substituição (dry-run)
./scripts/deploy-cicd.sh development --dry-run
```

### Verificar Template Gerado
```bash
# Gerar main.tf de teste
./scripts/deploy-cicd.sh development --validate

# Verificar se todas as variáveis foram substituídas
grep -n "{{" main.tf || echo "✅ Todas as variáveis foram substituídas"

# Validar Terraform no arquivo gerado
terraform validate
```

---

## 🎯 3. Teste de Plano Terraform

### Plano Completo (Sem Apply)
```bash
# Carregar variáveis de teste
source test-vars.env

# Gerar configuração
./scripts/deploy-cicd.sh development --validate

# Executar plano Terraform
terraform init
terraform plan -out=test.tfplan

# Analisar o plano
terraform show test.tfplan
```

### Verificar Recursos Planejados
```bash
# Contar recursos que serão criados
terraform show -json test.tfplan | jq '.planned_values.root_module.resources | length'

# Listar tipos de recursos
terraform show -json test.tfplan | jq -r '.planned_values.root_module.resources[].type' | sort | uniq -c

# Verificar recursos específicos
terraform show -json test.tfplan | jq '.planned_values.root_module.resources[] | select(.type=="aws_dms_replication_instance")'
```

---

## 💰 4. Teste com Recursos Mínimos

### Configuração de Teste Econômica
```bash
# Criar configuração mínima para teste
cat > test-minimal.env << 'EOF'
export PROJECT_NAME="test-dms-minimal"
export ENVIRONMENT="development"
# Use seus recursos AWS reais aqui
export VPC_ID="vpc-SEU_VPC_ID"
export SUBNET_ID_1="subnet-SEU_SUBNET_1"
export SUBNET_ID_2="subnet-SEU_SUBNET_2"
export SOURCE_SECURITY_GROUP_ID="sg-SEU_SG_SOURCE"
export TARGET_SECURITY_GROUP_ID="sg-SEU_SG_TARGET"
export KMS_KEY_ARN="arn:aws:kms:us-east-1:SUA_CONTA:key/SEU_KMS_KEY"
# Configuração mínima para reduzir custos
export SOURCE_ENGINE="mysql"
export SOURCE_DB_HOST="localhost"  # Use um endpoint de teste
export SOURCE_DB_PORT="3306"
export SOURCE_DB_NAME="test_db"
export TARGET_ENGINE="postgres"
export TARGET_DB_HOST="localhost"  # Use um endpoint de teste
export TARGET_DB_PORT="5432"
export TARGET_DB_NAME="test_db"
export USE_SECRETS_MANAGER="false"
export SOURCE_DB_USERNAME="test"
export SOURCE_DB_PASSWORD="test123"
export TARGET_DB_USERNAME="test"
export TARGET_DB_PASSWORD="test123"
export MIGRATION_TYPE="full-load"  # Mais simples que CDC
export SOURCE_SCHEMA_NAME="test"
export SOURCE_TABLE_PATTERN="test_table"
export TARGET_SCHEMA_NAME="public"
export DMS_ENGINE_VERSION="3.5.2"
export MAINTENANCE_WINDOW="sun:03:00-sun:04:00"
export OWNER="test-team"
export COST_CENTER="testing"
EOF

# Carregar e testar
source test-minimal.env
./scripts/deploy-cicd.sh development

# Deploy apenas para validar (CUIDADO: Isso criará recursos AWS)
# terraform apply -auto-approve

# Lembrar de destruir após teste
# terraform destroy -auto-approve
```

---

## 🚀 5. Teste Completo

### Pré-requisitos para Teste Completo
```bash
# 1. Verificar credenciais AWS
aws sts get-caller-identity

# 2. Verificar permissões necessárias
aws iam simulate-principal-policy \
  --policy-source-arn $(aws sts get-caller-identity --query Arn --output text) \
  --action-names dms:CreateReplicationInstance \
  --resource-arns "*"

# 3. Verificar recursos existentes
aws ec2 describe-vpcs --query 'Vpcs[?IsDefault==`true`]'
aws ec2 describe-subnets --query 'Subnets[?DefaultForAz==`true`]'
```

### Configuração de Teste Completo
```bash
# Criar configuração com recursos reais
cat > test-complete.env << 'EOF'
# Substitua com seus recursos AWS reais
export PROJECT_NAME="test-dms-complete"
export ENVIRONMENT="development"
export VPC_ID="vpc-SEU_VPC_REAL"
export SUBNET_ID_1="subnet-SEU_SUBNET_REAL_1"
export SUBNET_ID_2="subnet-SEU_SUBNET_REAL_2"
export SOURCE_SECURITY_GROUP_ID="sg-SEU_SG_SOURCE_REAL"
export TARGET_SECURITY_GROUP_ID="sg-SEU_SG_TARGET_REAL"
export KMS_KEY_ARN="arn:aws:kms:us-east-1:SUA_CONTA:key/SEU_KMS_KEY_REAL"
export SOURCE_ENGINE="mysql"
export SOURCE_DB_HOST="seu-mysql.rds.amazonaws.com"
export SOURCE_DB_PORT="3306"
export SOURCE_DB_NAME="source_database"
export TARGET_ENGINE="postgres"
export TARGET_DB_HOST="seu-postgres.rds.amazonaws.com"
export TARGET_DB_PORT="5432"
export TARGET_DB_NAME="target_database"
export USE_SECRETS_MANAGER="true"
export SOURCE_SECRETS_ARN="arn:aws:secretsmanager:us-east-1:SUA_CONTA:secret:source-db"
export SOURCE_SECRETS_ROLE_ARN="arn:aws:iam::SUA_CONTA:role/dms-secrets-role"
export TARGET_SECRETS_ARN="arn:aws:secretsmanager:us-east-1:SUA_CONTA:secret:target-db"
export TARGET_SECRETS_ROLE_ARN="arn:aws:iam::SUA_CONTA:role/dms-secrets-role"
export MIGRATION_TYPE="full-load-and-cdc"
export SOURCE_SCHEMA_NAME="%"
export SOURCE_TABLE_PATTERN="%"
export TARGET_SCHEMA_NAME="public"
export DMS_ENGINE_VERSION="3.5.2"
export MAINTENANCE_WINDOW="sun:03:00-sun:04:00"
export OWNER="test-team"
export COST_CENTER="testing"
EOF
```

### Executar Teste Completo
```bash
# 1. Carregar configuração
source test-complete.env

# 2. Deploy completo
./scripts/deploy-cicd.sh development

# 3. Verificar deployment
terraform output

# 4. Testar operações DMS
./scripts/dms-operations.sh status

# 5. Testar conectividade (se endpoints estiverem configurados)
./scripts/dms-operations.sh start --wait --timeout=300

# 6. Monitorar
./scripts/dms-operations.sh monitor --summary

# 7. Parar e limpar
./scripts/dms-operations.sh stop --wait
terraform destroy -auto-approve
```

---

## 🔧 Testes de Scripts Individuais

### Testar Scripts de Operação
```bash
# Testar com task ARN fictício (para validar lógica)
export FAKE_TASK_ARN="arn:aws:dms:us-east-1:123456789012:task:ABCDEFGHIJKLMNOP"

# Testar parsing de argumentos
./scripts/start-dms.sh --help
./scripts/start-dms.sh --dry-run $FAKE_TASK_ARN

# Testar validações
./scripts/monitor-dms.sh --help
./scripts/monitor-dms.sh --json $FAKE_TASK_ARN
```

---

## 📊 Testes de Validação

### Criar Script de Validação Automatizada
```bash
cat > validate-deployment.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "🧪 Iniciando validação da implementação DMS..."

# 1. Validar sintaxe Terraform
echo "1️⃣ Validando sintaxe Terraform..."
terraform fmt -check
terraform validate
echo "✅ Sintaxe Terraform válida"

# 2. Validar scripts bash
echo "2️⃣ Validando scripts bash..."
for script in scripts/*.sh; do
    bash -n "$script"
    echo "✅ $script válido"
done

# 3. Testar substituição de template
echo "3️⃣ Testando substituição de template..."
source test-vars.env
./scripts/deploy-cicd.sh development --dry-run > /dev/null
echo "✅ Template substitution funcionando"

# 4. Validar plano Terraform
echo "4️⃣ Validando plano Terraform..."
./scripts/deploy-cicd.sh development --validate > /dev/null
terraform init -backend=false > /dev/null
terraform plan > /dev/null
echo "✅ Plano Terraform válido"

echo "🎉 Todas as validações passaram!"
EOF

chmod +x validate-deployment.sh
./validate-deployment.sh
```

---

## ⚠️ Considerações Importantes

### Custos de Teste
- **Validação (1-3)**: Gratuito
- **Teste Mínimo (4)**: ~$10-20/dia
- **Teste Completo (5)**: ~$50-100/dia

### Limpeza Após Testes
```bash
# Sempre destruir recursos após teste
terraform destroy -auto-approve

# Verificar se recursos foram removidos
aws dms describe-replication-instances
aws dms describe-replication-tasks
```

### Monitoramento de Custos
```bash
# Verificar custos estimados
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-02 \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

---

## 🎯 Recomendação de Teste

**Para desenvolvimento inicial:**
1. Execute validações 1-3 (gratuitas)
2. Use teste mínimo (4) apenas quando necessário
3. Reserve teste completo (5) para validação final

**Para produção:**
1. Execute todos os testes em ambiente de staging
2. Use CI/CD para automatizar validações
3. Monitore custos durante testes