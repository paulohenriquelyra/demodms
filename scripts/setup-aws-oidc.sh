#!/bin/bash

# Script para configurar AWS OIDC com GitHub Actions
# Mais seguro que usar Access Keys

set -e

echo "🔐 Configurando AWS OIDC para GitHub Actions..."

# Variáveis (ajuste conforme necessário)
GITHUB_REPO="paulohenriquelyra/demodms"
AWS_ACCOUNT_ID="YOUR_AWS_ACCOUNT_ID"  # Substitua pelo seu Account ID
ROLE_NAME="GitHubActionsRole"

# Criar policy para Terraform
cat > terraform-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dms:*",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:CreateSecurityGroup",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:AuthorizeSecurityGroupEgress",
                "iam:CreateRole",
                "iam:AttachRolePolicy",
                "iam:PassRole",
                "iam:GetRole",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "kms:Describe*",
                "kms:List*",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::terraform-state-bucket-name/*",
                "arn:aws:s3:::terraform-state-bucket-name"
            ]
        }
    ]
}
EOF

# Criar trust policy para OIDC
cat > trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:${GITHUB_REPO}:*"
                }
            }
        }
    ]
}
EOF

echo "📋 Arquivos de policy criados:"
echo "   - terraform-policy.json"
echo "   - trust-policy.json"
echo ""
echo "🔧 Próximos passos manuais na AWS:"
echo ""
echo "1. Criar OIDC Provider (se não existir):"
echo "   aws iam create-open-id-connect-provider \\"
echo "     --url https://token.actions.githubusercontent.com \\"
echo "     --client-id-list sts.amazonaws.com \\"
echo "     --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1"
echo ""
echo "2. Criar IAM Role:"
echo "   aws iam create-role \\"
echo "     --role-name ${ROLE_NAME} \\"
echo "     --assume-role-policy-document file://trust-policy.json"
echo ""
echo "3. Criar e anexar policy:"
echo "   aws iam create-policy \\"
echo "     --policy-name TerraformDMSPolicy \\"
echo "     --policy-document file://terraform-policy.json"
echo ""
echo "   aws iam attach-role-policy \\"
echo "     --role-name ${ROLE_NAME} \\"
echo "     --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/TerraformDMSPolicy"
echo ""
echo "4. Adicionar secret no GitHub:"
echo "   AWS_ROLE_ARN=arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"
echo ""
echo "⚠️  IMPORTANTE: Substitua YOUR_AWS_ACCOUNT_ID pelo seu Account ID real!"