#!/bin/bash
# 安全监控脚本
# 监控异常连接并自动拉黑IP

LOG_FILE="/Users/mac/.openclaw/logs/security-monitor.log"
BLACKLIST_FILE="/Users/mac/.openclaw/logs/blacklisted-ips.txt"
ALERT_THRESHOLD=10  # 10次失败就拉黑
TIME_WINDOW=300  # 5分钟内

mkdir -p "$(dirname "$LOG_FILE")"

# 加载已拉黑的IP
declare -A BLACKLIST
if [ -f "$BLACKLIST_FILE" ]; then
    while IFS= read -r ip; do
        BLACKLIST["$ip"]=1
    done < "$BLACKLIST_FILE"
fi

# 分析SSH日志（假设日志在/var/log/auth.log或/var/log/system.log）
analyze_ssh_logs() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]') 分析SSH日志..." | tee -a "$LOG_FILE"

    # 查找失败登录尝试
    if [ -f "/var/log/system.log" ]; then
        recent_failures=$(grep -i "ssh.*failed\|ssh.*invalid" /var/log/system.log | tail -100)
    fi

    if [ -z "$recent_failures" ]; then
        echo "✅ 没有发现异常SSH失败" | tee -a "$LOG_FILE"
        return
    fi

    # 统计IP失败次数
    declare -A failure_counts
    while IFS= read -r line; do
        # 提取IP地址（简化版，实际需要更复杂的正则）
        ip=$(echo "$line" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
        if [ -n "$ip" ]; then
            ((failure_counts["$ip"]++))
        fi
    done <<< "$recent_failures"

    # 检查是否超过阈值
    for ip in "${!failure_counts[@]}"; do
        count=${failure_counts["$ip"]}

        if [ "$count" -ge "$ALERT_THRESHOLD" ]; then
            if [ -z "${BLACKLIST[$ip]}" ]; then
                echo "🚨 警告：IP $ip 失败登录 $count 次！" | tee -a "$LOG_FILE"

                # 拉黑IP（使用pfctl或ipfw）
                block_ip "$ip"

                # 记录到黑名单
                echo "$ip" >> "$BLACKLIST_FILE"
                BLACKLIST["$ip"]=1

                # 发送飞书通知
                send_alert "$ip" "$count"
            fi
        fi
    done
}

# 拉黑IP
block_ip() {
    local ip=$1
    echo "🔒 拉黑IP：$ip" | tee -a "$LOG_FILE"

    # 方法1：使用pfctl（macOS防火墙）
    # 注意：需要sudo权限和正确的pf配置
    sudo pfctl -t badhosts -T add "$ip" 2>/dev/null

    # 方法2：使用ipfw（旧版macOS）
    # sudo ipfw add deny all from "$ip" to any 2>/dev/null

    # 方法3：使用pf锚点（更可靠）
    # 需要预先配置pf规则
}

# 发送飞书告警
send_alert() {
    local ip=$1
    local count=$2

    # 查询IP地理位置
    geo_info=$(curl -s "http://ip-api.com/json/$ip" 2>/dev/null)
    country=$(echo "$geo_info" | grep -o '"country":"[^"]*"' | cut -d'"' -f4)

    # 发送消息
    /usr/bin/openclaw message send \
        --channel feishu \
        --target "user:ou_a0bc076f9ce1b841c901774f326c3f6b" \
        --message "🚨 **安全告警**

检测到异常登录尝试！

🌍 IP地址：$ip
🏳 地理位置：$country
📊 失败次数：$count
⏰ 时间：$(date '+%Y-%m-%d %H:%M:%S')

已自动拉黑该IP！"
}

# 检查端口开放状态
check_open_ports() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 检查开放端口..." | tee -a "$LOG_FILE"

    # 使用lsof检查监听端口
    open_ports=$(lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk 'NR>1 {print $9}' | cut -d: -f2 | sort -u)

    if [ -n "$open_ports" ]; then
        echo "当前开放的端口：" | tee -a "$LOG_FILE"
        echo "$open_ports" | tee -a "$LOG_FILE"

        # 检查是否有未授权的端口开放
        suspicious_ports=$(echo "$open_ports" | grep -vE '^(22|80|443|3000|8080|)$')
        if [ -n "$suspicious_ports" ]; then
            echo "⚠️ 发现可疑端口：$suspicious_ports" | tee -a "$LOG_FILE"

            /usr/bin/openclaw message send \
                --channel feishu \
                --target "user:ou_a0bc076f9ce1b841c901774f326c3f6b" \
                --message "⚠️ **端口安全告警**

发现可疑开放端口！

🔴 端口：$suspicious_ports
⏰ 时间：$(date '+%Y-%m-%d %H:%M:%S')

请检查是否为正常使用！"
        fi
    fi
}

# 主函数
main() {
    echo "=== 安全监控启动 ===" | tee -a "$LOG_FILE"

    analyze_ssh_logs
    check_open_ports

    echo "=== 监控完成 ===" | tee -a "$LOG_FILE"
}

main
