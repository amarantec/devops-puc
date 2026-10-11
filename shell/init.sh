#!/usr/bin/env bash
set -o pipefail
echo "Iniciando DB\n"
docker start kgkm-db

echo "===============================================\n"

echo "Iniciando Ngrok"
ngrok http 4000 &

echo "===============================================\n"
