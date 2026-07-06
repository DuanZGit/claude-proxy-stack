# claude-proxy-stack

> Claude Code 无头服务器一键代理栈：cc-switch + headroom + agnes-ai

在无头 Linux 服务器上，用纯命令行工具链接管 Claude Code 的 API 路由，将流量转发到任意 LLM 后端（本配置以 agnes-2.0-flash 为例）。

**零 Web UI，纯 CLI/TUI 交互。**

## 架构

```
Claude Code CLI
    ↓ ANTHROPIC_BASE_URL=http://127.0.0.1:15721
cc-switch proxy (port 15721)
    ↓ Anthropic Messages → OpenAI Chat Completions (格式转换)
headroom proxy (port 8787)
    ↓ 上下文优化 + 缓存
agnes-ai API (https://apihub.agnes-ai.com)
```

三层代理串联，每层职责清晰：

| 层级 | 工具 | 端口 | 职责 |
|------|------|------|------|
| 1 | cc-switch | 15721 | Anthropic ↔ OpenAI 格式转换，provider 路由，settings.json takeover |
| 2 | headroom | 8787 | 上下文压缩优化，请求缓存，速率限制 |
| 3 | agnes-ai | 远程 | 最终 LLM 后端 |

## 依赖

- **Python 3.10+** — headroom 运行时
- **Rust 1.91+** — cc-switch 二进制（预编译也可）
- **Claude Code** — 目标客户端
- **Linux** — 当前仅验证过 Linux x86_64

## 快速开始

### 1. 安装 headroom

```bash
pip install headroom-ai
```

### 2. 安装 cc-switch-cli

```bash
curl -fsSL https://raw.githubusercontent.com/SaladDay/cc-switch-cli/main/install.sh | bash
```

### 3. 配置 headroom

复制 `config/headroom.env.example` 为 `.env`，填入你的 API Key：

```bash
cp config/headroom.env.example config/headroom.env
# 编辑 OPENAI_API_KEY
```

启动 headroom：

```bash
bash scripts/start-headroom.sh
```

### 4. 配置 cc-switch

```bash
# 添加 provider（指向 headroom）
cc-switch provider add \
  --app claude \
  --name "agnes" \
  --base-url "http://127.0.0.1:8787" \
  --api-key "$OPENAI_API_KEY" \
  --model "agnes-2.0-flash" \
  --api-format "openai_chat" \
  --id "agnes"

# 切换到该 provider
cc-switch provider switch claude agnes

# 启用 proxy 并启动 daemon
cc-switch proxy enable --app claude
cc-switch daemon start
```

### 5. 创建 cc 快捷命令

```bash
cat > ~/.local/bin/cc << 'EOF'
#!/bin/bash
exec claude --dangerously-skip-permissions "$@"
EOF
chmod +x ~/.local/bin/cc
```

### 6. 验证

```bash
cc -p "say hello"
# 应返回 agnes-2.0-flash 的响应
```

## 文件结构

```
claude-proxy-stack/
├── scripts/
│   ├── start-headroom.sh      # headroom 启动脚本
│   ├── start-cc-switch.sh     # cc-switch 启动脚本
│   └── stop-all.sh            # 停止所有服务
├── config/
│   ├── headroom.env.example   # headroom 环境变量模板
│   └── cc-switch-provider.json # cc-switch provider 配置导出
├── docs/
│   └── troubleshooting.md     # 故障排查指南
├── systemd/
│   ├── headroom.service       # headroom systemd 用户服务
│   └── cc-switch.service      # cc-switch systemd 用户服务
├── README.md
└── .gitignore
```

## 工作原理

### cc-switch proxy 的 Takeover 机制

cc-switch 启动后会修改 `~/.claude/settings.json`：

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:15721",
    "ANTHROPIC_AUTH_TOKEN": "PROXY_MANAGED",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-6",
    "ANTHROPIC_DEFAULT_SONNET_MODEL_NAME": "agnes-2.0-flash"
  }
}
```

- `ANTHROPIC_BASE_URL` 指向本地 proxy
- `ANTHROPIC_AUTH_TOKEN` 设为占位符，proxy 自动注入真实 API Key
- 模型名称映射让 Claude Code 以为自己在调 claude-sonnet，实际走 agnes

### 格式转换流程

```
Claude Code 发送 (Anthropic format):
  POST /v1/messages
  { "model": "claude-sonnet-4-6", "messages": [...] }
       ↓ cc-switch proxy 转换
headroom 收到 (OpenAI format):
  POST /v1/chat/completions
  { "model": "agnes-2.0-flash", "messages": [...] }
       ↓ headroom 优化/缓存
agnes-ai 返回 (OpenAI format)
       ↓ headroom 透传
cc-switch proxy 转换回 Anthropic format
       ↓
Claude Code 收到标准 Anthropic 响应
```

## 多模型切换

```bash
# 添加新 provider
cc-switch provider add --app claude --name "other-model" \
  --base-url "http://127.0.0.1:8787" \
  --api-key "your-key" \
  --model "other-model" \
  --api-format "openai_chat"

# 热切换（无需重启 Claude Code）
cc-switch provider switch claude other-model
```

## 故障排查

见 [docs/troubleshooting.md](docs/troubleshooting.md)。

## 与上游项目的关系

本项目基于以下开源项目组装：

- **[SaladDay/cc-switch-cli](https://github.com/SaladDay/cc-switch-cli)** — proxy 和 provider 管理
- **[mozilla-ai/headroom](https://github.com/mozilla-ai/headroom)** — 上下文优化代理

本项目是**配置和部署方案**，不是上游项目的 fork。上游项目的更新可直接沿用。

## License

MIT
