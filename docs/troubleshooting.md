# Troubleshooting Guide

## cc-switch proxy not responding on port 15721

```bash
# Check if daemon is running
ps aux | grep cc-switch | grep -v grep

# Check proxy status
cc-switch proxy show --app claude

# Restart
cc-switch daemon stop
cc-switch daemon start
```

## headroom proxy not responding on port 8787

```bash
# Check if running
ps aux | grep headroom | grep -v grep

# Check health
curl -s http://127.0.0.1:8787/health

# Check logs
tail -f ~/.headroom/logs/proxy.log
```

## Claude Code returns 401 authentication error

- Verify `ANTHROPIC_AUTH_TOKEN` in `~/.claude/settings.json` is `PROXY_MANAGED`
- Check provider API key is correctly set in cc-switch database
- Test direct connection: `curl -X POST http://127.0.0.1:15721/v1/messages ...`

## cc-switch database locked error

```bash
# Kill all cc-switch processes
cc-switch daemon stop
pkill -f "cc-switch"

# Wait and retry
sleep 2
cc-switch daemon start
```

## Headroom returns 401 to agnes-ai

- Verify `OPENAI_API_KEY` in `config/headroom.env` is correct
- Test directly: `curl -X POST https://apihub.agnes-ai.com/v1/chat/completions ...`
- Check headroom logs: `tail -f ~/.headroom/logs/proxy.log | grep 401`

## Port conflicts

```bash
# Check what's listening on ports
ss -tlnp | grep -E '(15721|8787|8323)'

# Kill conflicting processes
pkill -f "openbridge"  # port 8323
```

## Format conversion errors

- Ensure provider `api-format` is set to `openai_chat` for agnes-ai
- Check cc-switch proxy logs for conversion errors
- Verify headroom is configured with `--backend anyllm --anyllm-provider openai`
