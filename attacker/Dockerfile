FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    medusa \
    hydra \
    nmap \
    enum4linux \
    smbclient \
    curl \
    ftp \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Manter container em execução para permitir docker exec
CMD ["sleep", "infinity"]
