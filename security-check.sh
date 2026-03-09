#!/bin/bash
# 系统安全检查脚本

echo "=== 🔍 OpenClaw 系统安全检查报告 ==="
echo "检查时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 1. 检查系统版本
echo "📊 1. 系统信息"
echo "----------------------------------------"
sw_vers
echo ""

# 2. 检查防火墙状态
echo "🔥 2. 防火墙状态"
echo "----------------------------------------"
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
echo ""

# 3. 检查SSH远程登录状态
echo "🔐 3. SSH远程登录状态"
echo "----------------------------------------"
/usr/sbin/systemsetup -getremotelogin 2>/dev/null || echo "需要sudo权限才能查看"
echo ""

# 4. 检查监听端口
echo "🔌 4. 监听端口"
echo "----------------------------------------"
# 使用netstat或lsof
if command -v netstat &>/dev/null; then
    netstat -an | grep LISTEN | grep -v "127.0.0.1" | head -10
elif command -v lsof &>/dev/null; then
    lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | grep -v "127.0.0.1" | head -10
else
    echo "未找到netstat或lsof命令"
fi
echo ""

# 5. 检查fail2ban状态
echo "🛡️ 5. fail2ban防护状态"
echo "----------------------------------------"
if command -v fail2ban-client &>/dev/null; then
    echo "fail2ban已安装"
    echo "尝试查看SSH防护状态..."
    fail2ban-client status sshd 2>/dev/null || echo "需要sudo权限或服务未运行"
else
    echo "fail2ban未安装"
fi
echo ""

# 6. 检查最近的登录尝试
echo "📋 6. 最近的登录尝试（需要sudo）"
echo "----------------------------------------"
if [ -f "/var/log/system.log" ]; then
    echo "查找最近1小时的SSH相关日志..."
    grep -i "ssh" /var/log/system.log | tail -20
fi
echo ""

# 7. 检查异常进程
echo "⚙️ 7. 可疑进程检查"
echo "----------------------------------------"
ps aux | grep -E "(ssh|nc|ncat|telnet)" | grep -v grep
echo ""

# 8. 检查网络连接
echo "🌐 8. 当前网络连接"
echo "----------------------------------------"
if command -v lsof &>/dev/null; then
    lsof -iTCP -sTCP:ESTABLISHED 2>/dev/null | head -10
fi
echo ""

# 9. 检查CPU和内存使用
echo "💻 9. 系统资源使用"
echo "----------------------------------------"
top -l 1 -n 10 | head -15
echo ""

echo "=== ✅ 检查完成 ==="
echo ""
echo "💡 建议："
echo "- 定期查看fail2ban日志：tail -100 /usr/local/var/log/fail2ban.log"
echo "- 监控开放端口：lsof -nP -iTCP -sTCP:LISTEN"
echo "- 检查异常登录：grep -i 'failed.*login' /var/log/system.log"
