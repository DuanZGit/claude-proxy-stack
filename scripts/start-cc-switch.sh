#!/bin/bash
# cc-switch proxy daemon startup script

echo "Starting cc-switch proxy daemon..."

# Stop any existing instance
cc-switch daemon stop 2>/dev/null || true
sleep 1

# Start daemon
cc-switch daemon start 2>&1

# Wait for proxy to be ready
for i in $(seq 1 10); do
  if curl -s http://127.0.0.1:15721/ >/dev/null 2>&1; then
    echo "cc-switch proxy is running on port 15721"
    exit 0
  fi
  sleep 1
done

echo "ERROR: cc-switch proxy failed to start"
exit 1
