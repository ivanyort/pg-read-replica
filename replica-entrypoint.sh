#!/bin/sh
set -eux

PGDATA_DIR="${PGDATA:-/var/lib/postgresql/data}"

# Se estiver como root, corrige dono/permissões e reexecuta este script como 'postgres'
if [ "$(id -u)" = "0" ] && [ -z "${ALREADY_DROPPED_PRIVS:-}" ]; then
  chown -R postgres:postgres "$PGDATA_DIR" || true
  chmod 700 "$PGDATA_DIR" || true
  # reexecuta este mesmo script como postgres (preservando env)
  if command -v su-exec >/dev/null 2>&1; then
    ALREADY_DROPPED_PRIVS=1 exec su-exec postgres /bin/sh -c 'exec /usr/local/bin/replica-entrypoint.sh'
  elif command -v gosu >/dev/null 2>&1; then
    ALREADY_DROPPED_PRIVS=1 exec gosu postgres /bin/sh -c 'exec /usr/local/bin/replica-entrypoint.sh'
  else
    echo "Nenhum su-exec/gosu encontrado" >&2
    exit 1
  fi
fi

# Daqui pra baixo já roda como 'postgres'
# Espera o primário ficar pronto
until pg_isready -h pg-primary -p 5432 -U user -d postgres; do
  echo "Aguardando pg-primary..."
  sleep 2
done

# Se não há cluster ainda, clona via basebackup e ativa standby
if [ ! -f "$PGDATA_DIR/PG_VERSION" ]; then
  echo "Executando pg_basebackup..."
  PGPASSWORD="${PGPASSWORD:?var PGPASSWORD undefined}" \
  pg_basebackup -R -X stream -C -S pgslot1 \
    -h pg-primary -p 5432 -U "${PGUSER:?var PGUSER undefined}" \
    -D "$PGDATA_DIR" -v
  echo "hot_standby = on" >> "$PGDATA_DIR/postgresql.auto.conf"
fi

# Sobe o postgres em standby
exec postgres \
  -c listen_addresses='*' \
  -c wal_level=logical \
  -c max_wal_senders=50 \
  -c max_replication_slots=50 \
  -c hot_standby=on \
  -c hot_standby_feedback=on \
  -c max_standby_streaming_delay='10min' \
  -c "log_line_prefix=%m [%p] %u@%d %r %a "

