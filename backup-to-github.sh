#!/bin/bash
# OpenClaw Workspace 自动化备份脚本
# 每2天晚上8:00执行
# 
# 使用方法：
# 1. 确保已配置好 git remote（包含 token）
# 2. 通过 cron 或 launchctl 设置定时任务

WORKSPACE="/Users/mac/.openclaw/workspace"
FEISHU_TARGET="user:ou_a0bc076f9ce1b841c901774f326c3f6b"
REPO="BitCrowder/openclaw-workspace"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始备份 OpenClaw workspace..."

cd "$WORKSPACE" || exit 1

# 检查是否有改动
if git diff-index --quiet HEAD --; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 没有文件改动，跳过备份"
    exit 0
fi

# 添加所有文件
git add .

# 提交
COMMIT_MSG="Auto backup: $(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "$COMMIT_MSG"

# 推送
git push

if [ $? -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ 备份成功！"

    # 发送飞书通知
    MESSAGE="✅ **OpenClaw Workspace 备份成功**

📅 时间：$(date '+%Y-%m-%d %H:%M')
🔗 仓库：https://github.com/$REPO
📝 提交：$COMMIT_MSG"

    openclaw message send --channel feishu --target "$FEISHU_TARGET" --message "$MESSAGE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ 备份失败！"

    # 发送失败通知
    MESSAGE="❌ **OpenClaw Workspace 备份失败**

📅 时间：$(date '+%Y-%m-%d %H:%M')
🔗 仓库：https://github.com/$REPO"

    openclaw message send --channel feishu --target "$FEISHU_TARGET" --message "$MESSAGE"
fi
