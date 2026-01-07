# Script PowerShell para configurar novo repositório Git com pipeline CI/CD

Write-Host "Configurando novo repositório..." -ForegroundColor Green

# Verificar se git está inicializado
if (-not (Test-Path ".git")) {
    Write-Host "Inicializando repositório Git..." -ForegroundColor Yellow
    git init
}

# Adicionar arquivos ao staging
Write-Host "Adicionando arquivos ao staging..." -ForegroundColor Yellow
git add .

# Fazer commit inicial
Write-Host "Fazendo commit inicial..." -ForegroundColor Yellow
git commit -m "feat: initial commit with terraform infrastructure and CI/CD pipeline

- Add Terraform DMS module
- Add GitLab CI/CD pipeline  
- Add testing scripts
- Add Kiro IDE integration hooks"

# Configurar remote
Write-Host "Para conectar ao repositório remoto, execute:" -ForegroundColor Cyan
Write-Host "git remote add origin URL_DO_SEU_REPOSITORIO" -ForegroundColor White
Write-Host "git branch -M main" -ForegroundColor White
Write-Host "git push -u origin main" -ForegroundColor White

Write-Host "Setup concluído!" -ForegroundColor Green