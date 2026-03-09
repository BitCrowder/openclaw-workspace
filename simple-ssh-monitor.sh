#!/bin/bash
# 简单的SSH入侵检测脚本（不依赖fail2ban）

LOG_FILE="/Users/mac/.openclaw/logs/ssh-intrusion.log"
BLACKLIST_FILE="/Users/mac/.openclaw/logs/ssh-blacklist.txt"
ALERT_THRESHOLD=5  # 5次失败就告警

mkdir -p "$(dirname "$LOG_FILE")"

# 加载已拉黑的IP
declare -A BLACKLIST
if [ -f "$BLACKLIST_FILE" ]; then
    while IFS= read -r ip; do
        BLACKLIST["$ip"]=1
    done < "$BLACKLIST_FILE"
fi

# 检查SSH日志
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 扫描SSH日志..." | tee -a "$LOG_FILE"

# 使用log命令搜索SSH相关事件
if command -v log &>/dev/null; then
    # 搜索最近1小时的SSH失败
    RECENT_FAILURES=$(log show --predicate 'eventMessage contains "ssh" AND eventMessage contains "failed"' --last 1h --style compact 2>/dev/null)
    
    if [ -n "$RECENT_FAILURES" ]; then
        echo "发现SSH失败尝试："
        echo "$RECENT_FAILURES" | tee -a "$LOG_FILE"
    fi
    
    # 搜索最近1小时的SSH成功登录
    RECENT_SUCCESS=$(log show --predicate 'eventMessage contains "ssh" AND eventMessage contains "Accepted"' --last 1h --style compact 2>/dev/null)
    
    if [ -n "$RECENT_SUCCESS" ]; then
        echo "发现SSH成功登录："
        echo "$RECENT_SUCCESS" | tee -a "$LOG_FILE"
    fi
fi

# 统计失败次数（简化版）
FAILURE_COUNT=0
if [ -n "$RECENT_FAILURES" ]; then
    FAILURE_COUNT=$(echo "$RECENT_FAILURES" | grep -c "failed")
fi

if [ "$FAILURE_COUNT" -ge "$ALERT_THRESHOLD" ]; then
    ALERT_MSG="⚠️ **SSH入侵告警**

检测到 $FAILURE_COUNT 次SSH失败尝试！

⏰ 时间：$(date '+%Y-%m-%d %H:%M:%S')

请立即检查系统日志：
\`\`\`
log show --predicate 'eventMessage contains \"ssh\"' --last 1h
\`\`\`"

    echo "$ALERT_MSG" | tee -a "$LOG_FILE"
    
    # 发送飞书通知
    /usr/bin/openclaw message send \
        --channel feishu \
        --target "user:ou_a0bc076f9ce1b841c901774f326c3f6b" \
        --message "$ALERT_MSG"
    
    echo "已发送飞书告警" | tee -a "$LOG_FILE"
fi

echo "扫描完成" | tee -a "$LOG_FILE"
