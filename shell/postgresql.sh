#!/usr/bin/env bash
podman run -p 5432:5432 \
           --name kgkm-db \
           --network kgkm-network \
           -e POSTGRES_PASSWORD=123456 \
           -e POSTGRES_USER=amarante \
           -e POSTGRES_DB=kgkm_dev \
           -v kgkm-db-data:/var/lib/postgresql \
           -d docker.io/library/postgres:18
