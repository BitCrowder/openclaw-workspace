#!/bin/bash
# SSH攻击痕迹检查脚本

echo "=== 🔍 SSH攻击痕迹检查 ==="
echo "检查时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 1. 检查最近的SSH连接日志
echo "📋 1. 最近的SSH连接日志"
echo "----------------------------------------"
if [ -f "/var/log/system.log" ]; then
    echo "最近24小时的SSH相关日志："
    log show --predicate 'eventMessage contains "ssh"' --last 24h --style compact 2>/dev/null | tail -50
    
    # 如果log show失败，尝试直接读取
    if [ $? -ne 0 ]; then
        grep -i "ssh" /var/log/system.log | tail -50
    fi
else
    echo "日志文件不存在"
fi
echo ""

# 2. 检查失败的登录尝试
echo "❌ 2. 失败的登录尝试"
echo "----------------------------------------"
if [ -f "/var/log/system.log" ]; then
    grep -i "failed\|invalid\|authentication.*failure" /var/log/system.log | grep -i ssh | tail -20
fi
echo ""

# 3. 检查当前SSH连接
echo "🔌 3. 当前的SSH连接"
echo "----------------------------------------"
# 使用who或w命令
w 2>/dev/null || echo "无法查看当前登录用户"
echo ""

# 4. 检查最近登录的用户
echo "👤 4. 最近的登录用户"
echo "----------------------------------------"
last | head -20
echo ""

# 5. 检查SSH配置
echo "⚙️ 5. SSH配置文件"
echo "----------------------------------------"
if [ -f "/etc/ssh/sshd_config" ]; then
    echo "SSH服务器配置："
    grep -vE "^#|^$" /etc/ssh/sshd_config | head -30
else
    echo "无法读取SSH配置（需要sudo）"
fi
echo ""

# 6. 检查SSH密钥
echo "🔑 6. 授权的SSH密钥"
echo "----------------------------------------"
if [ -f "$HOME/.ssh/authorized_keys" ]; then
    echo "已授权的密钥："
    cat "$HOME/.ssh/authorized_keys"
else
    echo "未找到authorized_keys文件"
fi
echo ""

# 7. 检查SSH会话历史
echo "📊 7. SSH会话历史"
echo "----------------------------------------"
ls -la /tmp/ 2>/dev/null | grep -i ssh || echo "无SSH会话文件"
echo ""

echo "=== ✅ 检查完成 ==="
echo ""
echo "💡 建议查看更详细的日志："
echo "sudo log show --predicate 'subsystem == \"com.apple.openssh\"' --last 3d"
