#!/bin/bash
# macOS上安装fail2ban（需要brew）

echo "🛡️ 安装fail2ban..."

# 检查是否安装了brew
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew未安装，请先安装："
    echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit 1
fi

# 安装fail2ban
brew install fail2ban

# 创建配置目录
sudo mkdir -p /usr/local/etc/fail2ban

# 创建jail配置
sudo tee /usr/local/etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
# 封禁时间（秒）
bantime = 86400

# 查找时间窗口（秒）
findtime = 600

# 最大失败次数
maxretry = 3

# 封禁动作
action = %(action_)s
         %(mta)s-whois[name=%(name)s, dest="%(destemail)s"]

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/system.log
maxretryban
EOF

# 创建SSH过滤器
sudo tee /usr/local/etc/fail2ban/filter.d/sshd.local > /dev/null <<EOF
[Definition]
failregex = ^%(__prefix_line)sFailed (password|publickey) for .* from <HOST>( port \d+)?$
            ^%(__prefix_line)sUser .* not allowed because not in any group .* from <HOST>( port \d+)?$
EOF

# 启动fail2ban
sudo brew services start fail2ban

# 设置开机自启
sudo brew services start fail2ban

echo "✅ fail2ban安装并启动成功！"
echo "📊 查看状态：sudo fail2ban-client status sshd"
echo "📊 查看被封禁的IP：sudo fail2ban-client status sshd | grep 'Banned IP'"
