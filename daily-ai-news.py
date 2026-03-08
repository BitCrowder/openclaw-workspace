#!/usr/bin/env python3
"""
每日AI新闻推送脚本
通过OpenClaw发送到飞书
特性：限定时间范围、去重、记录已发送新闻
"""
import json
import subprocess
import sys
import urllib.request
import urllib.error
import hashlib
import os
import re
from datetime import datetime, timedelta
from urllib.parse import urlparse

# 已发送新闻记录文件
SENT_NEWS_FILE = '/Users/mac/.openclaw/workspace/.sent-news.json'

def load_sent_news():
    """加载已发送的新闻记录"""
    if os.path.exists(SENT_NEWS_FILE):
        try:
            with open(SENT_NEWS_FILE, 'r') as f:
                return json.load(f)
        except:
            return {}
    return {}

def save_sent_news(sent_news):
    """保存已发送的新闻记录"""
    with open(SENT_NEWS_FILE, 'w') as f:
        json.dump(sent_news, f, indent=2)

def is_url_sent(url, sent_news):
    """检查URL是否已发送过"""
    url_hash = hashlib.md5(url.encode()).hexdigest()
    return url_hash in sent_news

def mark_url_sent(url, sent_news):
    """标记URL为已发送"""
    url_hash = hashlib.md5(url.encode()).hexdigest()
    sent_news[url_hash] = {
        'url': url,
        'sent_at': datetime.now().isoformat()
    }

def extract_date_from_content(content, title):
    """从内容或标题中提取日期"""
    # 日期匹配模式
    date_patterns = [
        r'(\d{4})-(\d{1,2})-(\d{1,2})',  # 2026-01-15
        r'(\d{4})[年](\d{1,2})[月](\d{1,2})[日]',  # 2026年1月15日
        r'(\d{1,2})[月](\d{1,2})[日]',  # 1月15日
        r'(\d{1,2})/(\d{1,2})/(\d{2,4})',  # 1/15/2026
    ]

    text = f"{title} {content}"

    for pattern in date_patterns:
        matches = re.findall(pattern, text)
        if matches:
            # 返回第一个匹配的日期
            match = matches[0]
            if len(match) == 3:
                year, month, day = match
                # 标准化年份
                if len(year) == 2:
                    year = '20' + year
                # 补齐月份和日期
                if len(month) == 1:
                    month = '0' + month
                if len(day) == 1:
                    day = '0' + day
                return f"{year}-{month}-{day}"

    return None

def validate_url(url, timeout=5):
    """验证URL是否可访问"""
    try:
        req = urllib.request.Request(url, method='HEAD')
        response = urllib.request.urlopen(req, timeout=timeout)
        if response.status == 200:
            return True, response.status
        else:
            return False, response.status
    except urllib.error.URLError as e:
        print(f"  ❌ URL验证失败: {url} - {str(e)}")
        return False, str(e)
    except Exception as e:
        print(f"  ❌ URL验证失败: {url} - {str(e)}")
        return False, str(e)

def send_feishu_message(message):
    """通过OpenClaw CLI发送消息到飞书"""
    target = "user:ou_a0bc076f9ce1b841c901774f326c3f6b"
    cmd = ['openclaw', 'message', 'send', '--channel', 'feishu', '--target', target, '--message', message]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        if result.returncode == 0:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] ✅ 消息已发送到飞书")
            return True
        else:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] ❌ 发送失败: {result.stderr}")
            return False
    except subprocess.TimeoutExpired:
        print(f"[{datetime.now().strftime('%H:%M:%S')}] ❌ 发送超时")
        return False
    except Exception as e:
        print(f"[{datetime.now().strftime('%H:%M:%S')}] ❌ 错误: {e}")
        return False

def main():
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 开始搜索AI新闻...")

    sent_news = load_sent_news()
    print(f"[已发送记录: {len(sent_news)} 条]")

    cmd = [
        'curl', '-X', 'POST', 'https://api.tavily.com/search',
        '-H', 'Content-Type: application/json',
        '-d', json.dumps({
            "api_key": "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",
            "query": "AI artificial intelligence 最新新闻 2026",
            "search_depth": "basic",
            "max_results": 10,
            "days": 1,
            "include_raw_content": True
        }),
        '-s'
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        data = json.loads(result.stdout)

        results = data.get('results', [])

        if not results:
            print("🔍 今天暂无新资讯")
            return

        print(f"\n[验证URL有效性并去重...]")
        valid_items = []
        for idx, item in enumerate(results, 1):
            url = item.get('url', '')
            title = item.get('title', '')

            if is_url_sent(url, sent_news):
                print(f"\n{idx}. 跳过（已发送）: {title[:50]}...")
                continue

            print(f"\n{idx}. 检查: {url}")
            is_valid, status = validate_url(url)
            if is_valid:
                print(f"  ✅ 可访问 (Status: {status})")
                valid_items.append(item)
            else:
                print(f"  ❌ 跳过 (Status: {status})")

            if len(valid_items) >= 5:
                break

        if not valid_items:
            print("❌ 没有新内容可推送（已去重或链接无法访问）")
            return

        today = datetime.now().strftime("%Y年%m月%d日")
        message = f"🤖 **每日AI资讯**\n\n📅 {today}\n\n"

        for idx, item in enumerate(valid_items[:5], 1):
            title = item.get('title', '无标题')
            url = item.get('url', '')
            content = item.get('raw_content', item.get('content', ''))

            # 提取日期
            extracted_date = extract_date_from_content(content, title)

            # 清理content
            snippet = content.replace('\n', ' ').replace('\r', ' ').strip()
            if len(snippet) > 150:
                snippet = snippet[:150] + '...'

            message += f"**{idx}. {title}**\n"
            if extracted_date:
                message += f"🕒 {extracted_date}\n"
            message += f"{snippet}\n"
            message += f"🔗 {url}\n\n"

        message += f"\n📊 来源: Tavily Search\n⏰ 推送时间: {datetime.now().strftime('%H:%M')}"

        print(f"\n[准备发送消息]\n{message[:200]}...")
        success = send_feishu_message(message)

        if success:
            for item in valid_items:
                mark_url_sent(item.get('url', ''), sent_news)
            save_sent_news(sent_news)
            print(f"[{datetime.now().strftime('%H:%M:%S')}] ✅ AI新闻推送完成，已更新发送记录")
        else:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] ❌ 推送失败")
            sys.exit(1)

    except json.JSONDecodeError as e:
        print(f"❌ JSON解析失败: {e}")
        sys.exit(1)
    except subprocess.TimeoutExpired:
        print("❌ API请求超时")
        sys.exit(1)
    except Exception as e:
        print(f"❌ 错误: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
