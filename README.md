# Cyber Security Lab: Brute Force & Mitigation (Medusa)

**Projeto 002** · Bootcamp Cyber Security (Riachuelo) · [DIO](https://www.dio.me/)

---

## Disclaimer do Projeto

> **1. Uso de IA e Vibe Coding:** Este repositório faz parte de uma iniciativa pessoal em que aproveito os projetos do bootcamp para **testar o uso de assistentes de IA na implementação**, explorando a abordagem de *vibe coding*.  
>
> **Principal ferramenta:** [Cursor](https://cursor.sh/) (cursor.ai) — utilizada como ambiente de desenvolvimento integrado com IA.  
> **Outras ferramentas em avaliação:** Gemini, Abacus, Tess e Claude.  
>
> O objetivo é comparar e avaliar criticamente o resultado final das entregas produzidas com o auxílio de cada IA. Além disso, estes repositórios serão **publicados no LinkedIn do autor** como portfólio de projetos.

---

## Sobre o Desafio

Este repositório documenta a entrega do desafio *"Simulando um Ataque de Brute Force de Senhas com Medusa e Kali Linux"*, parte do bootcamp de Cyber Security da DIO em parceria com Riachuelo.

O objetivo é implementar, documentar e compartilhar um projeto prático que simula cenários de ataque de força bruta em ambiente controlado, utilizando **Kali Linux** e **Medusa** contra ambientes vulneráveis intencionais.

> ⚠️ **Aviso:** Todas as atividades foram realizadas em laboratório isolado, com fins exclusivamente educacionais. O uso dessas técnicas contra sistemas sem autorização é ilegal.

---

## Objetivos de Aprendizagem

- Compreender ataques de força bruta em diferentes serviços (FTP, Web, SMB)
- Utilizar Kali Linux e Medusa para auditoria de segurança em ambiente controlado
- Documentar processos técnicos de forma clara e estruturada
- Reconhecer vulnerabilidades comuns e propor medidas de mitigação
- Utilizar o GitHub como portfólio técnico para compartilhar documentação e evidências

---

## Requisitos do Projeto

| Requisito | Status |
|-----------|--------|
| Configurar ambiente com Kali Linux e Metasploitable 2 (rede host-only) | Pendente |
| Ataque de força bruta em FTP | Pendente |
| Automação em formulário web (DVWA) | Pendente |
| Password spraying em SMB com enumeração de usuários | Pendente |
| Documentação: wordlists, comandos, validação e mitigação | Pendente |

---

## Ambiente de Laboratório

| Componente | Descrição | IP |
|------------|-----------|-----|
| **Atacante** | Kali Linux | `[A SER PREENCHIDO]` |
| **Alvo** | Metasploitable 2 | `[A SER PREENCHIDO]` |
| **Rede** | VirtualBox Host-only Adapter | — |

### Pré-requisitos

- VirtualBox (ou outro hipervisor compatível)
- Imagem do [Kali Linux](https://www.kali.org/get-kali/)
- Imagem do [Metasploitable 2](https://sourceforge.net/projects/metasploitable/files/Metasploitable2/)
- (Opcional) DVWA para cenários web

---

## Metodologia

1. **Reconhecimento** — Varredura de portas e serviços com Nmap
2. **Análise de vulnerabilidades** — Identificação de serviços suscetíveis a força bruta
3. **Exploração** — Ataques simulados com Medusa (FTP, SSH, SMB e/ou web)
4. **Mitigação** — Propostas de hardening e boas práticas

---

## Execução e Evidências

### Comandos executados

```bash
# Subir a stack
docker compose up -d

# Reconhecimento (Nmap)
docker exec attacker nmap -sV -p 21,80,139,445 ftp smb dvwa

# FTP brute force
docker exec attacker medusa -h ftp -M ftp -U /wordlists/users.txt -P /wordlists/passwords.txt

# SMB enumeração de usuários
docker exec attacker enum4linux -U smb

# SMB password spraying
docker exec attacker medusa -h smb -M smbnt -U /wordlists/users.txt -P /wordlists/passwords.txt

# DVWA com Medusa (tem limitações — vide documentação)
docker exec attacker medusa -h dvwa -M web-form -m FORM:"login.php" \
  -m FORM-DATA:"post?username=&password=&Login=Login" \
  -m DENY-SIGNAL:"Login failed" -u admin -P /wordlists/passwords.txt

# DVWA com Hydra (recomendado para formulários web)
./scripts/dvwa-hydra-attack.sh
```

Ou execute o script automatizado: `./scripts/run-attacks.sh`

### DVWA com Hydra (totalmente automatizado)

O script `./scripts/dvwa-hydra-attack.sh` **não exige configuração manual** — cria o banco, faz login e executa o Hydra automaticamente. Basta `docker compose up -d` e rodar o script.

### Limitação do Medusa em formulários web

O Medusa (`web-form`) não lida bem com o DVWA devido a:
- **Token CSRF** — não extrai nem envia tokens dinâmicos
- **HTTP 302** — interpreta mal redirects após login

Para brute force em formulários web como o DVWA, use o **Hydra** (incluído no lab). Detalhes em [docs/dvwa-setup-e-hydra.md](docs/dvwa-setup-e-hydra.md).

### Wordlists utilizadas

- `wordlists/users.txt` — msfadmin, admin, root, ftp, user, guest
- `wordlists/passwords.txt` — msfadmin, password, 123456, admin, root, ftp, letmein

### Resultados da validação

| Alvo | Credencial encontrada | Validação |
|------|------------------------|-----------|
| **FTP** | `msfadmin:msfadmin` | Medusa ACCOUNT FOUND; login via ftp |
| **SMB** | `msfadmin:msfadmin` | `smbclient -L //smb/share -U msfadmin%msfadmin` — acesso ao share |
| **DVWA** | `admin:password` | Configurar manualmente; usar Hydra: `./scripts/dvwa-hydra-attack.sh` |

### Screenshots e logs

Organize capturas de tela em `docs/images/`.

---

## Mitigação e Boas Práticas

### FTP

- Desabilitar login de usuários locais quando possível; preferir SFTP/SCP
- Política de senha forte (comprimento, complexidade)
- Limitar tentativas de login (fail2ban, TCP Wrappers)
- Logs de autenticação e monitoramento

### SMB

- Desabilitar SMBv1 (obsoleto e vulnerável)
- Restringir ou desabilitar acesso anônimo
- Bloqueio de conta após N tentativas falhas
- Firewall: restringir portas 139/445 a redes confiáveis

### DVWA / aplicações web

- Rate limiting em formulários de login
- CAPTCHA ou desafio humano após falhas
- Account lockout após X tentativas
- Tokens CSRF em todas as formas sensíveis
- Autenticação em duas etapas (2FA) quando disponível

### Monitoramento geral

- fail2ban ou equivalente para bloqueio automático
- Centralização e análise de logs de autenticação
- IDS/IPS para detecção de padrões de força bruta

---

## Estrutura do Repositório

```
├── README.md
├── docker-compose.yml
├── Makefile
├── attacker/
│   └── Dockerfile
├── targets/
│   ├── ftp/
│   │   ├── Dockerfile
│   │   └── vsftpd.conf
│   └── smb/
│       ├── Dockerfile
│       └── smb.conf
├── wordlists/
│   ├── users.txt
│   └── passwords.txt
├── scripts/
│   ├── run-attacks.sh
│   └── dvwa-hydra-attack.sh
├── docs/
│   ├── desafio.md
│   ├── plano-implementacao.md
│   ├── dvwa-setup-e-hydra.md
│   └── images/
└── logs/
```

---

## Referências

- [Descrição detalhada do desafio](docs/desafio.md)
- [Plano de implementação](docs/plano-implementacao.md)
- [DVWA: Setup manual e Hydra](docs/dvwa-setup-e-hydra.md) — limitação do Medusa, configuração obrigatória e brute force com Hydra
- [Kali Linux](https://www.kali.org/)
- [Medusa – Documentação](https://github.com/jmk-foofus/medusa)
- [Nmap – Manual Oficial](https://nmap.org/book/man.html)
- [DVWA – Damn Vulnerable Web Application](https://github.com/digininja/DVWA)

---

## Minha versão do desafio

O desafio original propõe o uso de VMs (Kali Linux e Metasploitable 2) no VirtualBox com rede host-only. **Nesta versão, todo o ambiente é executado com Docker**, aproveitando a flexibilidade permitida pela cláusula de adaptação do desafio.

### Ambiente com Docker

| Componente | Descrição | Imagem/Container |
|------------|-----------|------------------|
| **Atacante** | Kali + Medusa, Hydra, Nmap, Enum4linux, smbclient | Build: `attacker/Dockerfile` |
| **Alvo FTP** | vsftpd com usuário msfadmin:msfadmin | Build: `targets/ftp/` |
| **Alvo SMB** | Samba com msfadmin, admin, guest | Build: `targets/smb/` |
| **Alvo Web** | DVWA (formulários de login) | `vulnerables/web-dvwa` |
| **Rede** | Docker network bridge | `lab_network` |

### Portas mapeadas no host

- FTP: `2121`
- SMB: `4455` (445), `1399` (139)
- DVWA: `4280`

### Pré-requisitos (versão Docker)

- [Docker](https://docs.docker.com/get-docker/) e Docker Compose
- Portas 2121, 4280, 4455, 1399 disponíveis

### Como executar

```bash
# Subir a stack
docker compose up -d

# Shell interativo no atacante
docker exec -it attacker bash

# Ou executar ataques automáticos
./scripts/run-attacks.sh
```

**DVWA:** Use o Hydra (automático): `./scripts/dvwa-hydra-attack.sh` ou `make attack-dvwa`

### Metodologia (versão Docker)

1. **Subir a stack** — `docker-compose up -d` para iniciar atacante e alvos
2. **Reconhecimento** — Nmap a partir do container atacante contra a rede Docker
3. **Análise de vulnerabilidades** — Identificação de serviços expostos
4. **Exploração** — Ataques com Medusa contra FTP, SMB e/ou DVWA
5. **Mitigação** — Documentação das medidas de hardening aplicáveis

### Requisitos (versão adaptada)

| Requisito | Status |
|-----------|--------|
| Configurar ambiente com Docker (atacante + alvos) | Concluído |
| Ataque de força bruta em FTP | Concluído |
| Automação em formulário web (DVWA) | Concluído |
| Password spraying em SMB com enumeração de usuários | Concluído |
| Documentação: wordlists, comandos, validação e mitigação | Concluído |

---

*Projeto desenvolvido no âmbito do Bootcamp Cyber Security (Riachuelo), DIO.*
