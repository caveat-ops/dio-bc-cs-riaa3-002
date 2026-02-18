FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    vsftpd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Criar usuário msfadmin com senha msfadmin (estilo Metasploitable)
RUN useradd -m -s /bin/bash msfadmin \
    && echo "msfadmin:msfadmin" | chpasswd

# Copiar configuração
COPY vsftpd.conf /etc/vsftpd.conf

# Criar diretório necessário e ajustar permissões
RUN mkdir -p /var/run/vsftpd/empty \
    && chown msfadmin:msfadmin /home/msfadmin

EXPOSE 21

CMD ["vsftpd", "/etc/vsftpd.conf"]
