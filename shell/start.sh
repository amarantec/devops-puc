#!/usr/bin/env bash
docker run -d \
  --name kgkm-app \
  --env MIX_ENV=prod \
  --env PHX_SERVER=true \
  --env POSTGRES_USER=amarante \
  --env POSTGRES_PASSWORD=123456 \
  --env POSTGRES_DB=kgkm_dev \
  --env DB_HOST=kgkm-db \
  --env DATABASE_URL=ecto://amarante:123456@kgkm-db:5432/kgkm_dev \
  --env SECRET_KEY_BASE=jIlg+EFOdnRXBDj9FzsHayNYVCt/M7uO68sJo42fqMnH0p5y4A3bLra+dojncHoM
  --env GUARDIAN_SECRET_KEY=c2ajmR3TEZ4lLU3NjejUVqL2BrPVfBYofTqQSBWEE6KhvtsPCgF00stJiGI3PHZt%

  --env PORT=4000 \
  -p 4000:4000 \
  --network kgkm-network \
  kgkm:latest
