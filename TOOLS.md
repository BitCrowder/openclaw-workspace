# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

Add whatever helps you do your job. This is your cheat sheet.

---

## Email Configuration

### 网易邮箱大师

- **邮箱地址：** `huangsj325@163.com`
- **IMAP 服务器：** `imap.163.com:993` (SSL/TLS)
- **SMTP 服务器：** `smtp.163.com:465` (SSL/TLS)
- **授权码：** `ZSVhn3AwBPqgk4Ar`
- **配置文件：** `~/.config/himalaya/config.toml`
- **状态：** IMAP 连接被网易安全策略阻止（Unsafe Login 错误）
- **定时提醒：** 每天早上 8:00 通过 Telegram 提醒查看邮件

**说明：**
- 当前使用 Himalaya CLI 管理邮件
- 由于 IMAP 连接限制，暂时使用定时提醒方式
- 邮件汇总脚本已创建：`/Users/mac/.openclaw/workspace/email-summary.sh`

---

## Search APIs

### Tavily Search

- **API Key:** `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`
- **Endpoint:** https://api.tavily.com/search
- **Usage:** When user asks for web search, use `exec` to call Tavily API directly (OpenClaw's built-in `web_search` only supports Brave API)
- **Example:**
  ```bash
  curl -X POST "https://api.tavily.com/search" \
    -H "Content-Type: application/json" \
    -d '{
      "api_key": "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",
      "query": "搜索内容",
      "search_depth": "basic",
      "max_results": 5
    }'
  ```
