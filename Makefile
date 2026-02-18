.PHONY: up down build attack attack-dvwa shell

up:
	docker compose up -d

down:
	docker compose down

build:
	docker compose build --no-cache

attack:
	./scripts/run-attacks.sh

attack-dvwa:
	./scripts/dvwa-hydra-attack.sh

shell:
	docker exec -it attacker bash
