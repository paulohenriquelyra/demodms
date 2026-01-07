#!/bin/bash

# Script para configurar Terraform Backend S3 + DynamoDB
# Execute este script ANTES de configurar o backend no Terraform

set -e

echo "🏗️ Configurando Terraform Backend..."

# Variáveis
AWS_REGION="us-east-1"
BUCKET_SUFFIX=$(openssl rand -hex 4)
BUCKET_NAME="terraform-state-dms-${BUCKET_SUFFIX}"
DYNAMODB_TABLE="terraform-locks-dms"

echo "📦 Criando bucket S3: $BUCKET_NAME"

# Criar bucket S3
aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION

# Configurar versionamento
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

# Configurar criptografia
aws s3api put-bucket-encryption \
    --bucket $BUCKET_NAME \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

# Bloquear acesso público
aws s3api put-public-access-block \
    --bucket $BUCKET_NAME \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "🔒 Criando tabela DynamoDB: $DYNAMODB_TABLE"

# Criar tabela DynamoDB para locks
aws dynamodb create-table \
    --table-name $DYNAMODB_TABLE \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region $AWS_REGION

# Aguardar tabela ficar ativa
echo "⏳ Aguardando tabela DynamoDB ficar ativa..."
aws dynamodb wait table-exists --table-name $DYNAMODB_TABLE --region $AWS_REGION

echo "✅ Backend configurado com sucesso!"
echo ""
echo "📋 Configurações para usar no backend.tf:"
echo "   bucket         = \"$BUCKET_NAME\""
echo "   dynamodb_table = \"$DYNAMODB_TABLE\""
echo "   region         = \"$AWS_REGION\""
echo ""
echo "🔧 Próximos passos:"
echo "1. Atualize o arquivo backend.tf com os valores acima"
echo "2. Execute: terraform init"
echo "3. Execute: terraform plan"