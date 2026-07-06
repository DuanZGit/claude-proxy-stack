#!/bin/bash
# Stop all proxy services

echo "Stopping headroom proxy..."
pkill -f "headroom.cli proxy" 2>/dev/null && echo "  stopped" || echo "  not running"

echo "Stopping cc-switch proxy..."
cc-switch daemon stop 2>/dev/null && echo "  stopped" || echo "  not running"

echo "All proxies stopped."
