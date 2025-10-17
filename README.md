# 🐘 PostgreSQL 16 Primary/Replica with Docker Compose

This project provides a **ready-to-run PostgreSQL 16 replication environment** using **Docker Compose**.  
It implements a **physical streaming replication** setup via `pg_basebackup`, configured with **SCRAM-SHA-256 authentication**, and is fully compatible with **logical replication** or **Change Data Capture (CDC)** tools like **Qlik Replicate**.

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

## 🧰 Use Cases

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
   docker exec -it pg-primary psql -U $POSTGRES_USER -d $POSTGRES_DB      -c "SELECT application_name, client_addr, state, sync_state FROM pg_stat_replication;"
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
- Ensure you **never commit your real `.env` file** with passwords.  
- You can safely extend this setup with connection pooling (PgBouncer) or monitoring tools (pg_stat_statements, Prometheus exporters, etc.).
