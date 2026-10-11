#!/usr/bin/env bash

set -a
source .env
set +a

export MIX_ENV=${MIX_ENV:-test}
mix test
