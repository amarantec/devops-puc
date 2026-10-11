# 1. Migrações
docker compose exec app /app/bin/aiyf eval "Aiyf.Release.migrate"

# 2. Seeds
docker compose exec app /app/bin/aiyf eval 'Application.ensure_all_started(:aiyf); Code.eval_file(Application.app_dir(:aiyf, "priv/repo/seeds.exs"))'
