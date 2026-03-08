#!/bin/bash

# 邮件汇总脚本 - 每日邮件总结
# 作者：叶仔
# 用途：获取昨日邮件并汇总

set -e

# 配置
TELEGRAM_CHAT_ID="8530347024"
DATE_YESTERDAY=$(date -v-1d +"%Y-%m-%d")
DATE_DISPLAY=$(date -v-1d +"%Y年%m月%d日")

# 输出分隔符
function separator() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# 输出标题
function header() {
    echo "📧 邮件日报 - $DATE_DISPLAY"
    separator
}

# 获取昨日邮件（IMAP）
function fetch_yesterday_emails() {
    echo "📅 昨日邮件概览"
    separator

    # 使用 himalaya 获取邮件列表，筛选昨天的
    himalaya envelope list \
        --output json \
        2>/dev/null | \
    python3 -c "
import sys
import json
from datetime import datetime, timedelta

emails = json.load(sys.stdin)

# 昨天的日期范围
yesterday = datetime.now() - timedelta(days=1)
yesterday_start = yesterday.replace(hour=0, minute=0, second=0, microsecond=0)
yesterday_end = yesterday.replace(hour=23, minute=59, second=59, microsecond=999999)

yesterday_emails = []
for email in emails:
    # 解析日期（格式可能不同，需要适配）
    email_date = email.get('date', '')
    if 'yesterday' in email_date.lower() or '$DATE_YESTERDAY' in email_date:
        yesterday_emails.append(email)

if not yesterday_emails:
    print('✅ 昨天没有收到新邮件')
else:
    print(f'📨 共收到 {len(yesterday_emails)} 封邮件')
    print('')
    
    for i, email in enumerate(yesterday_emails[:10], 1):  # 最多显示10封
        subject = email.get('subject', '(无主题)')
        sender = email.get('from', {}).get('email', '未知发件人')
        date = email.get('date', '未知时间')
        
        print(f'{i}. {subject}')
        print(f'   发件人: {sender}')
        print(f'   时间: {date}')
        print('')
"
}

# 主函数
main() {
    header
    fetch_yesterday_emails
    separator
    echo "💡 提示：要查看完整邮件内容，请打开邮箱大师客户端"
}

# 执行
main
