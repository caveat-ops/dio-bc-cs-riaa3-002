FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    samba \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Criar usuários com senhas fracas (estilo Metasploitable)
RUN useradd -m -s /bin/bash msfadmin \
    && useradd -m -s /bin/bash admin \
    && useradd -m -s /bin/bash guest \
    && echo "msfadmin:msfadmin" | chpasswd \
    && echo "admin:admin" | chpasswd \
    && echo "guest:guest" | chpasswd

# Adicionar usuários ao Samba
RUN (echo "msfadmin"; echo "msfadmin") | smbpasswd -a -s msfadmin \
    && (echo "admin"; echo "admin") | smbpasswd -a -s admin \
    && (echo "guest"; echo "guest") | smbpasswd -a -s guest

# Criar diretório do share
RUN mkdir -p /home/share \
    && chown msfadmin:msfadmin /home/share \
    && chmod 755 /home/share

COPY smb.conf /etc/samba/smb.conf

# Script para iniciar nmbd (porta 139) e smbd (porta 445)
RUN echo '#!/bin/sh\nnmbd -D\nsmbd --foreground --no-process-group' > /start.sh && chmod +x /start.sh

EXPOSE 139 445

CMD ["/start.sh"]
