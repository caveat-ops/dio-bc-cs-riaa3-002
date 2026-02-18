# DVWA: Configuração Manual e Brute Force com Hydra

## Limitação do Medusa em formulários web

O **Medusa** (módulo `web-form`) tem dificuldades com o DVWA devido a:

1. **Token CSRF** — O formulário de login usa `user_token` que muda a cada requisição. O Medusa não extrai nem envia tokens dinâmicos.
2. **Resposta HTTP 302** — O DVWA redireciona após login (sucesso ou falha). O Medusa interpreta mal o código 302 e retorna: *"The answer was NOT successfully received, understood, and accepted... error code 302"*.
3. **Módulo SMB (smbnt)** — Com Samba, o Medusa pode reportar `ACCOUNT FOUND` com `ERROR (0xFFFFFF:UNKNOWN_ERROR_CODE)` — falsos positivos. Validar sempre com `smbclient`.

O Medusa continua sendo usado com sucesso para **FTP** e **SMB** neste lab. Para formulários web como o DVWA, recomendamos o **Hydra**.

---

## Automação completa (Hydra)

O script `dvwa-hydra-attack.sh` **não exige nenhuma configuração manual**. Ele automatiza:

1. **Create/Reset Database** — Detecta se o banco precisa ser criado e envia o POST para `setup.php`
2. **Login** — Extrai o token CSRF, faz login com `admin:password` e obtém o cookie de sessão
3. **Security=Low** — Enviado via cookie na requisição do Hydra (não é necessário visitar a página)
4. **Brute Force** — Executa o Hydra contra o módulo vulnerável

Basta executar `./scripts/dvwa-hydra-attack.sh` ou `make attack-dvwa` após `docker compose up -d`.

## Configuração manual (opcional, para uso no navegador)

Se quiser acessar o DVWA manualmente no navegador (http://localhost:4280):

### Passo 1: Criar/Resetar o banco

Clique em **"Create / Reset Database"** na primeira tela.

### Passo 2: Login

Use as credenciais padrão: **admin** / **password**

### Passo 3: DVWA Security

Em **"DVWA Security"**, selecione **"Low"** e clique em **"Submit"**.

---

## Brute Force no DVWA com Hydra

O Hydra lida melhor com formulários web. Para o módulo de Brute Force do DVWA (`/vulnerabilities/brute/`), é necessário uma **sessão autenticada** (cookie `PHPSESSID`).

### Comando manual (se preferir executar dentro do container)

Para executar dentro do container atacante:

```bash
docker exec -it attacker bash
# Dentro do container:
curl -s -c /tmp/c.txt -b /tmp/c.txt -L -d "username=admin&password=password&Login=Login" http://dvwa/login.php > /dev/null
PHPSESSID=$(grep PHPSESSID /tmp/c.txt | awk '{print $NF}')
hydra -l admin -P /wordlists/passwords.txt dvwa http-get-form \
  "/vulnerabilities/brute/:username=^USER^&password=^PASS^&Login=Login:F=incorrect:S=Welcome to the password protected" \
  -H "Cookie: PHPSESSID=$PHPSESSID; security=low" -t 4 -w 10 -v
```

**Nota:** O script `./scripts/dvwa-hydra-attack.sh` automatiza todo o fluxo (setup + login + Hydra).

### Usando o script automatizado

```bash
./scripts/dvwa-hydra-attack.sh
```

O script:

1. Extrai o token CSRF da página de login
2. Faz login com `admin:password` e obtém o cookie
3. Executa o Hydra contra o módulo Brute Force com a sessão válida

### Credencial esperada

- **Usuário:** `admin`
- **Senha:** `password`

Com security em **Low**, o Hydra deve identificar essa combinação rapidamente.
