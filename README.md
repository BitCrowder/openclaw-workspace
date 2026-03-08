# OpenClaw Workspace Backup

> 黄生的OpenClaw配置和脚本备份

## 📋 说明
这个仓库用于备份我的OpenClaw workspace，包含所有配置文件、自定义脚本和技能。

## 📁 主要内容

### 配置文件
- `AGENTS.md` - 工作空间核心配置
- `SOUL.md` - 助手灵魂文件（定义助手人设）
- `USER.md` - 用户信息（关于黄生）
- `IDENTITY.md` - 助手身份（叶仔）
- `TOOLS.md` - 工具和环境配置
- `HEARTBEAT.md` - 心跳任务配置

### 脚本
- `daily-ai-news.py` - 每日AI新闻推送脚本
- `daily-ai-news.sh` - 备用新闻推送脚本
- `email-summary.sh` - 邮件汇总脚本
- `generate-ai-news.py` - AI新闻生成脚本

### 技能 (skills/)
- `find-skills` - 技能发现助手
- `self-improving-agent` - 自我学习机制
- `summarize` - URL/文件摘要工具
- `vision-sandbox` - 视觉处理沙盒

## 🔄 自动备份
- **频率：** 每2天晚上8:00
- **方式：** 自动git add、commit、push到main分支
- **通知：** 备份完成后发送飞书消息

## 🛠️ 手动备份
如需手动备份，运行：
```bash
cd ~/.openclaw/workspace
git add .
git commit -m "Manual backup: $(date +%Y-%m-%d)"
git push
```

## ⚙️ 环境要求
- OpenClaw框架
- Python 3.x
- GitHub访问权限

---

*最后更新：2026-03-08*
