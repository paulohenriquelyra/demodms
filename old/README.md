# Arquivos Legados - Abordagem com Variables.tf

Esta pasta contém os arquivos da abordagem anterior que utilizava `variables.tf` e arquivos `.tfvars` separados.

## Arquivos Movidos

### `main.tf` (legado)
- Versão anterior que utilizava `var.` references
- Dependia de `variables.tf` e arquivos `.tfvars`
- Adequado para desenvolvimento local e testes

### `variables.tf` (legado)
- Definições de todas as variáveis do projeto
- Descrições detalhadas e validações
- Valores padrão para configurações comuns

### `terraform.tfvars.*.example` (legados)
- `terraform.tfvars.dev.example` - Configuração para desenvolvimento
- `terraform.tfvars.staging.example` - Configuração para staging
- `terraform.tfvars.prod.example` - Configuração para produção

## Por que foram movidos?

Seguindo a recomendação do **Tech Leader**, a nova abordagem utiliza:

1. **Variáveis inline no main.tf** - Para máxima portabilidade em CI/CD
2. **Template com substituição** - Para automação de pipelines
3. **Sem dependências externas** - Arquivo único e autossuficiente

## Como usar os arquivos legados?

Se precisar reverter para a abordagem anterior:

```bash
# Mover arquivos de volta
cp old/main.tf ./
cp old/variables.tf ./
cp old/terraform.tfvars.*.example ./

# Remover o main.tf atual (CI/CD)
rm main.tf

# Renomear o main.tf legado
mv old/main.tf main.tf
```

## Comparação das Abordagens

### Abordagem Legada (variables.tf)
✅ Mais fácil para desenvolvimento local  
✅ Validações de variáveis centralizadas  
✅ Reutilização de configurações  
❌ Múltiplos arquivos para gerenciar  
❌ Dependências externas (.tfvars)  
❌ Mais complexo para CI/CD  

### Abordagem Atual (inline CI/CD)
✅ Perfeito para CI/CD pipelines  
✅ Arquivo único e autossuficiente  
✅ Template com substituição automática  
✅ Sem dependências externas  
❌ Menos flexível para desenvolvimento local  
❌ Configuração inline mais verbosa  

## Recomendação

- **Use a abordagem atual (main.tf)** para produção e CI/CD
- **Use os arquivos legados** apenas para desenvolvimento local se necessário
- **Mantenha ambas as abordagens** para flexibilidade máxima

---

**Nota**: Os arquivos legados são mantidos para reversibilidade conforme especificado nos requisitos do projeto.