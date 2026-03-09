# 🔐 MacMini安全加固总结

## ⚠️ 紧急情况

- SSH被暴力破解40,000+次
- 攻击来自：荷兰、法国、俄罗斯
- 13个异常SSH连接

---

## 🔥 立即执行（今天）

### 1. 禁用SSH远程登录（最紧急）

```bash
sudo systemsetup -setremotelogin off
```

### 2. 检查是否成功

```bash
sudo systemsetup -getremotelogin
# 应该显示：Remote Login: Off
```

---

## 🔧 如果还需要SSH访问（必须修改！）

### 步骤1：备份配置

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
```

### 步骤2：修改SSH配置

```bash
sudo nano /etc/ssh/sshd_config
```

**修改以下内容：**

```bash
# 禁用密码登录
PasswordAuthentication no

# 只允许密钥登录
PubkeyAuthentication yes

# 禁用root登录
PermitRootLogin no

# 限制登录用户（只允许你自己的用户）
AllowUsers mac

# 修改默认端口（建议改成2222）
Port 2222
```

### 步骤3：生成SSH密钥对（如果没有）

```bash
# 在客户端机器上生成密钥
ssh-keygen -t ed25519 -C "你的邮箱"

# 复制公钥到服务器
ssh-copy-id -p 2222 mac@服务器IP
```

### 步骤4：重启SSH服务

```bash
sudo launchctl unload -w /System/Library/LaunchDaemons/ssh.plist
sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist
```

---

## 🛡️ 防火墙配置

### 启用并配置防火墙

```bash
# 确保防火墙开启
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# 阻止所有传入连接
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall on

# 只允许必要的服务
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/sbin/sshd

# 允许特定端口（根据需要）
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/sbin/cupsd  # 打印
```

### 禁用ICMP ping（防止被扫描）

```bash
sudo sysctl -w net.inet.icmp.icmplim=0
```

---

## 📊 安装fail2ban（防暴力破解）

### 运行安装脚本

```bash
bash ~/Library/Mobile\ Documents/com.apple.CloudDocs/.openclaw/workspace/install-fail2ban.sh
```

或者：

```bash
bash ~/.openclaw/workspace/install-fail2ban.sh
```

### 查看fail2ban状态

```bash
# 查看SSH防护状态
sudo fail2ban-client status sshd

# 查看被封禁的IP
sudo fail2ban-client status sshd | grep 'Banned IP'

# 手动解封IP（如果误封）
sudo fail2ban-client set sshd unbanip IP地址
```

---

## 📋 启动安全监控

### 运行监控脚本

```bash
bash ~/.openclaw/workspace/security-monitor.sh
```

### 设置定时监控（每小时检查一次）

```bash
# 复制定时任务
cp ~/Library/LaunchAgents/com.openclaw.security-monitor.plist ~/Library/LaunchAgents/com.openclaw.security-monitor.plist

# 加载任务
launchctl load ~/Library/LaunchAgents/com.openclaw.security-monitor.plist

# 查看任务状态
launchctl list | grep security-monitor
```

---

## 🔍 查看日志

```bash
# 查看SSH日志
tail -100 /var/log/system.log | grep -i ssh

# 查看监控日志
tail -100 ~/.openclaw/logs/security-monitor.log

# 查看fail2ban日志
tail -100 /usr/local/var/log/fail2ban.log
```

---

## ⚙️ 其他安全建议

### 1. 使用强密码
- 至少16位
- 包含大小写字母、数字、特殊符号
- 不要使用字典单词

### 2. 启用FileVault磁盘加密
```bash
sudo fdesetup enable
```

### 3. 定期更新系统
```bash
softwareupdate -ia
```

### 4. 检查异常进程
```bash
ps aux | grep -E "(ssh|nc|ncat|telnet)" | grep -v grep
```

### 5. 检查异常网络连接
```bash
lsof -iTCP -sTCP:ESTABLISHED
```

---

## 📞 紧急联系

如果发现异常活动：

1. 立即断开网络
2. 查看系统日志
3. 检查进程和连接
4. 必要时重装系统

---

## ✅ 检查清单

执行完以上步骤后，请确认：

- [ ] SSH远程登录已禁用（或改成密钥登录）
- [ ] SSH配置文件已修改（禁止密码、禁止root）
- [ ] 防火墙已启用并正确配置
- [ ] fail2ban已安装并运行
- [ ] 安全监控脚本已运行
- [ ] 定时监控已设置
- [ ] 日志可以正常查看

---

*生成时间：2026-03-09*
*MacOS版本：26.3 (Sequoia)*
