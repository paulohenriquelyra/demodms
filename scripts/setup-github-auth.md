# Configuração de Autenticação GitHub

## Opção 1: SSH (Recomendado)

Sua chave SSH pública:
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCcqdxFNHSsOMElMV7tSBQdZxYmBGaw3TBjGwiFejqPzZtr90alrhwa3H0kAtmreKV2ziIRT7l8TPVpeG9BACmOI2p4UEfbORxRXp47CuEusfG9CsPckFv40BFpO3B9K3hU2SNp/OX/+31widY8OUug3UeKWURNQJHIxxppTfvPukQC25O2/Wa9602zsLl6MmGh6CeoZQFHNemQGUE+p23xx3TzxC4TXF+xMHBtdrZOYCu4XKM7iSdoV7zDJjDaHqX74aax5Hbr5guVQKjBWqsSIYKlp0o4m2LxXcTrCD7sOweTCXNmIXgLzrLU7+iCQKm4II32rwWGM7v/Gk7egjRz paulofl@WNB041632BHZ
```

### Passos:
1. Vá para https://github.com/settings/keys
2. Clique em "New SSH key"
3. Cole a chave acima no campo "Key"
4. Dê um título como "WSL - Projeto DMS"
5. Clique em "Add SSH key"

## Opção 2: Personal Access Token

1. Vá para https://github.com/settings/tokens
2. Clique em "Generate new token (classic)"
3. Selecione os scopes: `repo`, `workflow`
4. Copie o token gerado
5. Execute: `git remote set-url origin https://TOKEN@github.com/paulohenriquelyra/demodms.git`

## Testando a Conexão

Após configurar, teste com:
```bash
wsl ssh -T git@github.com
```

Ou faça o push:
```bash
wsl git push -u origin main
```