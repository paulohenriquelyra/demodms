#!/bin/bash

# Script para configurar novo repositório Git com pipeline CI/CD

set -e

echo "🚀 Configurando novo repositório..."

# Verificar se git está inicializado
if [ ! -d ".git" ]; then
    echo "📁 Inicializando repositório Git..."
    git init
fi

# Adicionar arquivos ao staging
echo "📝 Adicionando arquivos ao staging..."
git add .

# Fazer commit inicial
echo "💾 Fazendo commit inicial..."
git commit -m "feat: initial commit with terraform infrastructure and CI/CD pipeline

- Add Terraform DMS module
- Add GitLab CI/CD pipeline
- Add testing scripts
- Add Kiro IDE integration hooks"

# Configurar remote (você precisa substituir pela URL do seu repositório)
echo "🔗 Para conectar ao repositório remoto, execute:"
echo "git remote add origin <URL_DO_SEU_REPOSITORIO>"
echo "git branch -M main"
echo "git push -u origin main"

echo "✅ Setup concluído!"