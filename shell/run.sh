#!/usr/bin/env bash

set -a
source .env 2>/dev/null || echo "No .env file found, using environment variables."
set +a

export MIX_ENV=${MIX_ENV:-dev}

if [ "$MIX_ENV" = "prod" ]; then
    echo "Starting in PRODUCTION mode..."
    exec mix phx.server --open
else
    echo "Starting in DEVELOPMENT mode..."
    mix ecto.setup
    exec mix phx.server --open
fi
