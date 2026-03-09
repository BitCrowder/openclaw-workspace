#!/bin/bash
# 正确的fail2ban配置和启动脚本

echo "🛡️ 修复fail2ban配置..."
echo ""

# 1. 停止服务
echo "1. 停止现有服务..."
brew services stop fail2ban 2>/dev/null
echo "✅ 服务已停止"
echo ""

# 2. 重新配置jail
echo "2. 重新配置SSH监控jail..."
sudo tee /opt/homebrew/etc/fail2ban/jail.local > /dev/null <<'EOF'
[DEFAULT]
# 禁禁时间（24小时）
bantime = 86400

# 查找时间窗口（10分钟）
findtime = 600

# 最大失败次数
maxretry = 5

[sshd]
enabled = true
port = 22,2222
filter = sshd
logpath = /var/log/system.log
maxretry = 3
bantime = 3600
action = %(action_)s
         %(mta)s-whois[name=%(name)s, dest="%(destemail)s", chain="%(chain)s"]
EOF

echo "✅ jail配置已更新"
echo ""

# 3. 检查并修复权限
echo "3. 修复文件权限..."
sudo chown -R root:wheel /opt/homebrew/etc/fail2ban
sudo chmod 644 /opt/homebrew/etc/fail2ban/jail.conf
sudo chmod 644 /opt/homebrew/etc/fail2ban/jail.local
echo "✅ 权限已修复"
echo ""

# 4. 重新启动服务
echo "4. 启动fail2ban服务..."
sudo brew services start fail2ban
echo "✅ 服务已启动"
echo ""

# 5. 等待并检查状态
echo "5. 等待服务启动..."
sleep 3
echo ""

# 6. 验证状态
echo "6. 验证fail2ban状态..."
STATUS_OUTPUT=$(fail2ban-client status 2>&1)
echo "$STATUS_OUTPUT"

if echo "$STATUS_OUTPUT" | grep -q "sshd"; then
    echo "✅ SSH监控jail已激活！"
else
    echo "⚠️ SSH监控jail未激活，检查日志"
    echo ""
    echo "查看日志："
    echo "sudo tail -100 /opt/homebrew/var/log/fail2ban.log"
fi
echo ""

# 7. 检查被封禁的IP
echo "7. 检查当前被封禁的IP..."
BANNED_IPS=$(fail2ban-client status sshd 2>&1 | grep "Banned IP" || echo "暂无")
if [ -n "$BANNED_IPS" ]; then
    echo "📋 已封禁的IP："
    echo "$BANNED_IPS"
else
    echo "📊 目前没有IP被封禁"
fi
echo ""

echo "=== ✅ fail2ban修复完成 ==="
echo ""
echo "💡 日常维护命令："
echo "查看状态：sudo fail2ban-client status sshd"
echo "查看日志：sudo tail -100 /opt/homebrew/var/log/fail2ban.log"
echo "解封IP：sudo fail2ban-client set sshd unbanip <IP>"
