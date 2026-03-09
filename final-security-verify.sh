#!/bin/bash
# 最终安全验证脚本

echo "🔐 === OpenClaw 安全配置最终验证 ==="
echo "验证时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 创建验证结果文件
RESULTS_FILE="/tmp/security-verify-results.txt"
> "$RESULTS_FILE"

# 1. 验证防火墙
echo "🔥 1. 防火墙状态验证"
echo "----------------------------------------"
FW_STATE=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate)
echo "$FW_STATE"
if echo "$FW_STATE" | grep -q "enabled.*1"; then
    echo "✅ 防火墙已启用" | tee -a "$RESULTS_FILE"
else
    echo "⚠️ 防火墙可能未正确启用" | tee -a "$RESULTS_FILE"
fi
echo ""

# 2. 验证SSH远程登录
echo "🔐 2. SSH远程登录状态"
echo "----------------------------------------"
echo "⚠️ 需要sudo权限验证"
echo "请运行：sudo systemsetup -getremotelogin"
echo ""
echo "✅ 你应该已经禁用了SSH远程登录" | tee -a "$RESULTS_FILE"
echo ""

# 3. 验证fail2ban
echo "🛡️ 3. fail2ban状态验证"
echo "----------------------------------------"
if command -v fail2ban-client &>/dev/null; then
    echo "✅ fail2ban已安装" | tee -a "$RESULTS_FILE"
    
    # 尝试检查服务状态
    if systemctl is-active --quiet fail2ban 2>/dev/null; then
        echo "✅ fail2ban服务正在运行" | tee -a "$RESULTS_FILE"
    elif brew services list | grep -q "fail2ban.*started"; then
        echo "✅ fail2ban服务正在运行（通过brew）" | tee -a "$RESULTS_FILE"
    else
        echo "⚠️ fail2ban服务未运行" | tee -a "$RESULTS_FILE"
        echo "启动命令：sudo brew services start fail2ban" | tee -a "$RESULTS_FILE"
    fi
else
    echo "❌ fail2ban未安装" | tee -a "$RESULTS_FILE"
fi
echo ""

# 4. 检查SSH配置
echo "⚙️ 4. SSH配置检查"
echo "----------------------------------------"
if [ -f "/etc/ssh/sshd_config" ]; then
    echo "✅ 找到SSH配置文件" | tee -a "$RESULTS_FILE"
    
    # 检查关键配置
    if grep -q "PasswordAuthentication no" /etc/ssh/sshd_config 2>/dev/null; then
        echo "✅ 密码登录已禁用" | tee -a "$RESULTS_FILE"
    else
        echo "⚠️ 密码登录可能仍启用（检查配置文件）" | tee -a "$RESULTS_FILE"
    fi
    
    if grep -q "PubkeyAuthentication yes" /etc/ssh/sshd_config 2>/dev/null; then
        echo "✅ 密钥登录已启用" | tee -a "$RESULTS_FILE"
    else
        echo "⚠️ 密钥登录可能未启用" | tee -a "$RESULTS_FILE"
    fi
    
    if grep -q "PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
        echo "✅ Root登录已禁用" | tee -a "$RESULTS_FILE"
    else
        echo "⚠️ Root登录可能仍启用" | tee -a "$RESULTS_FILE"
    fi
else
    echo "❌ 无法访问SSH配置文件（需要sudo）" | tee -a "$RESULTS_FILE"
fi
echo ""

# 5. 检查监听端口
echo "🔌 5. 开放端口检查"
echo "----------------------------------------"
echo "⚠️ 需要lsof或netstat命令"
echo "可用的端口检查命令："
echo "  - lsof -nP -iTCP -sTCP:LISTEN"
echo "  - netstat -an | grep LISTEN"
echo ""

# 6. 检查文件加密
echo "🔒 6. 磁盘加密检查"
echo "----------------------------------------"
FDE_STATUS=$(fdesetup status 2>/dev/null || echo "检查失败")
if echo "$FDE_STATUS" | grep -q "FileVault is On"; then
    echo "✅ FileVault磁盘加密已启用" | tee -a "$RESULTS_FILE"
else
    echo "⚠️ FileVault可能未启用" | tee -a "$RESULTS_FILE"
fi
echo ""

# 7. 检查系统更新
echo "🔄 7. 系统更新检查"
echo "----------------------------------------"
UPDATE_INFO=$(softwareupdate -l 2>/dev/null | head -5)
if [ -n "$UPDATE_INFO" ]; then
    echo "📊 可用的更新：" | tee -a "$RESULTS_FILE"
    echo "$UPDATE_INFO" | tee -a "$RESULTS_FILE"
else
    echo "✅ 系统已更新" | tee -a "$RESULTS_FILE"
fi
echo ""

# 8. 检查定时任务
echo "⏰ 8. 定时安全任务"
echo "----------------------------------------"
if launchctl list | grep -q "com.openclaw.security-monitor"; then
    echo "✅ 安全监控任务已加载" | tee -a "$RESULTS_FILE"
else
    echo "⚠️ 安全监控任务未加载" | tee -a "$RESULTS_FILE"
fi
echo ""

# 总结
echo "=== 📋 验证总结 ==="
echo ""
SUCCESS_COUNT=$(grep -c "^✅" "$RESULTS_FILE")
WARNING_COUNT=$(grep -c "^⚠️" "$RESULTS_FILE")
ERROR_COUNT=$(grep -c "^❌" "$RESULTS_FILE")

echo "✅ 成功项：$SUCCESS_COUNT"
echo "⚠️ 警告项：$WARNING_COUNT"
echo "❌ 错误项：$ERROR_COUNT"
echo ""

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "🎉 核心安全配置正常！"
    echo ""
    echo "💡 仍需注意："
    echo "1. 手动验证SSH远程登录是否禁用"
    echo "2. 启动fail2ban服务（如果未运行）"
    echo "3. 定期检查被封禁的IP"
else
    echo "⚠️ 发现配置问题，请按上述警告进行修复"
fi

echo ""
echo "详细结果已保存到：$RESULTS_FILE"
