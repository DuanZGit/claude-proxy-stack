#!/bin/bash
# Headroom proxy startup script
# Uses agnes-ai API hub as OpenAI-compatible backend

# Load env if exists
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../config/headroom.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

# Defaults
export OPENAI_API_KEY="${OPENAI_API_KEY:?ERROR: Set OPENAI_API_KEY in config/headroom.env}"
export HEADROOM_TELEMETRY="${HEADROOM_TELEMETRY:-off}"
export HEADROOM_MODE="${HEADROOM_MODE:-cache}"
export PYTHONUNBUFFERED=1

exec /usr/bin/python3 -u -m headroom.cli proxy \
  --port "${HEADROOM_PORT:-8787}" \
  --backend anyllm \
  --anyllm-provider openai \
  --openai-api-url "${AGNES_API_URL:-https://apihub.agnes-ai.com}" \
  --no-telemetry \
  --no-rate-limit \
  --mode "$HEADROOM_MODE" \
  --workers 1 \
  --limit-concurrency 500 \
  --max-connections 200 \
  --max-keepalive 50
