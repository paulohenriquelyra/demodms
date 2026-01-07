# Git Workflow e Padrões do Projeto

## Padrões de Commit
- Use conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`
- Commits em português são aceitos
- Sempre execute `terraform validate` e `terraform fmt` antes do commit

## Workflow de Branches
- `main`: branch principal, sempre deployável
- `develop`: branch de desenvolvimento
- `feature/*`: branches para novas funcionalidades
- `hotfix/*`: branches para correções urgentes

## Pipeline CI/CD
- Validação automática em todos os PRs
- Deploy manual apenas na branch main
- Scans de segurança com Trivy
- Planos Terraform salvos como artefatos

## Integração com Kiro
- Hooks automáticos para validação Terraform
- Botão manual para pre-commit checks
- Steering files para manter padrões consistentes