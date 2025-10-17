# Postgres 16 Primary/Replica via Docker Compose

Replicação física (streaming) com `pg_basebackup` e slot, sem healthcheck barulhento.

## Subir

1. Copie `.env.example` para `.env` e edite senhas.
2. `docker compose up -d`

## Arquivos

- `docker-compose.yaml` — serviços `pg-primary` e `pg-replica`
- `replica-entrypoint.sh` — corrige permissões, espera o primário, executa basebackup e inicia o standby
- `00_init.sql` — cria o usuário de replicação
- `01_pg_hba_replication.sh` — adiciona regra de replicação no `pg_hba.conf` do primário

## Comandos úteis

Estado da replicação (primário):
```bash
docker exec -it pg-primary psql -U $POSTGRES_USER -d $POSTGRES_DB -c \
"SELECT application_name, client_addr, state, sync_state FROM pg_stat_replication;"

