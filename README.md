# 🐘 PostgreSQL 16 Primary/Replica with Docker Compose

## Abstract
PostgreSQL 16 introduced the ability to create logical replication slots and perform logical decoding on standby (read replica) servers — a major enhancement for high availability and CDC workloads.

**Before PostgreSQL 16:** When you attempted to create a logical replication slot on a standby server, PostgreSQL would return an error saying:

> “logical decoding cannot be used while in recovery”

CDC tools only had the option to connect directly to the primary server to capture data changes.

**PostgreSQL 16 and Later:** You can now point CDC tools such as **Qlik Replicate** to a replica server instead of connecting to your primary. This works for logical replication and logical decoding operations.

### Key Benefits

**Load Distribution:** Offload CDC operations to read replicas, reducing the workload on your primary database.

**Seamless Failover:** If a standby is promoted to primary, CDC tools continue seamlessly following the logical replication stream without interruption.

**High Availability for CDC:** Enables new architectures for high availability and data synchronization across multiple systems or for auditing purposes.

## Project's Objective

This project provides a **ready-to-run PostgreSQL 16 replication environment** using **Docker Compose**.  
It implements a **physical streaming replication** setup via `pg_basebackup`, configured with **SCRAM-SHA-256 authentication**, and is fully compatible with **logical replication** or **Change Data Capture (CDC)** tools like **Qlik Replicate**, **Debezium**, or **pgoutput**.

## 🔍 Overview

The environment consists of two PostgreSQL containers:

| Role | Description |
|------|--------------|
| **Primary** | Initializes the main database cluster, enables WAL streaming and replication slots, and exposes port `5432`. |
| **Replica** | Automatically bootstraps from the primary using a custom `replica-entrypoint.sh`, keeps in sync through streaming replication, and runs on port `5433`. |

Both services are connected via a private Docker network (`pgnet`) and are fully isolated from your host environment.

## ⚙️ Features

- PostgreSQL **16.x** (Alpine-based image)  
- Secure authentication with **SCRAM-SHA-256**  
- Automatic replica initialization using **pg_basebackup**  
- **Custom entrypoint** script that waits for the primary and applies correct ownership/permissions  
- Logical replication–ready (`wal_level=logical`)  
- Clean startup without noisy healthchecks or excessive logs  
- Persistent volumes for both primary and replica data  

## 🧮 Use Cases

- Local testing of PostgreSQL replication behavior  
- Lab or demo setup for **CDC tools** (Qlik Replicate, Debezium, etc.)  
- Experimentation with failover, recovery, and WAL streaming  
- Educational purposes to understand PostgreSQL high availability mechanisms  

## 🚀 Quick Start

1. Copy `.env.example` to `.env` and edit credentials.
2. Run:
   ```bash
   docker compose up -d
   ```
3. Verify replication:
   ```bash
   docker exec -it pg-primary psql -U $POSTGRES_USER -d $POSTGRES_DB \
     -c "SELECT application_name, client_addr, state, sync_state FROM pg_stat_replication;"
   ```

## 🥪 Command Cheatsheet (create / start / stop / kill)

> Run these from the repository directory (where `docker-compose.yaml` lives). Replace service names when needed: `postgres_primary` and `postgres_replica` are the Compose **service** names; `pg-primary` and `pg-replica` are the **container** names.

### Create / Start
```bash
# build images (if you add a Dockerfile later) and start in background
docker compose up -d

# (re)create only one service
docker compose up -d postgres_replica

# show status of services
docker compose ps
```

### Stop / Start existing
```bash
# stop all services
docker compose stop

# stop a specific service
docker compose stop postgres_replica

# start services previously created (without recreating)
docker compose start
docker compose start postgres_replica

# restart
docker compose restart
docker compose restart postgres_replica
```

### Kill / Remove
```bash
# send SIGKILL to containers (force-stop)
docker kill pg-primary pg-replica

# remove stopped containers from this compose project
docker compose rm -f

# stop + remove containers, default network
docker compose down

# stop + remove + delete named volumes (⚠️ wipes data)
docker compose down -v
```

### Full reset (wipe data volumes)
```bash
# remove named volumes explicitly (safe if they exist)
docker volume rm pg_primary_data pg_replica_data 2>/dev/null || true

# or prune ALL unused volumes on the host (⚠️ global)
docker volume prune -f
```

### Logs & Exec
```bash
# live logs (all services)
docker compose logs -f

# logs for one service
docker compose logs -f postgres_replica

# exec into a container shell
docker exec -it pg-primary sh
docker exec -it pg-replica sh

# quick readiness check
docker exec -it pg-primary pg_isready -h localhost -p 5432
docker exec -it pg-replica pg_isready -h localhost -p 5432
```

### PSQL helpers
```bash
# connect to primary
docker exec -it pg-primary psql -U $POSTGRES_USER -d $POSTGRES_DB

# connect to replica (read-only)
docker exec -it pg-replica psql -U $POSTGRES_USER -d $POSTGRES_DB

# replication status (primary)
docker exec -it pg-primary psql -U $POSTGRES_USER -d $POSTGRES_DB \
  -c "SELECT application_name, client_addr, state, sync_state FROM pg_stat_replication;"

# wal receiver status (replica)
docker exec -it pg-replica psql -U $POSTGRES_USER -d $POSTGRES_DB \
  -c "SELECT status, slot_name, last_msg_send_time, last_msg_receipt_time FROM pg_stat_wal_receiver;"
```

## 📂 Project Structure

```
pg-primary-replica/
├── docker-compose.yaml
├── replica-entrypoint.sh
├── 00_init.sql
├── 01_pg_hba_replication.sh
├── .env.example
└── README.md
```

## 🛡️ Notes

- This setup is intended for **local/lab environments**, not for production.  
- You can safely extend this setup with connection pooling (PgBouncer) or monitoring tools (pg_stat_statements, Prometheus exporters, etc.).

