#!/bin/bash

# Daily AI News Pusher
# 每天早上8:30推送AI相关最新资讯

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始搜索AI新闻..."

# 使用Tavily Search API搜索AI新闻
curl -X POST "https://api.tavily.com/search" \
  -H "Content-Type: application/json" \
  -d '{
    "api_key": "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",
    "query": "AI artificial intelligence 最新新闻 2026",
    "search_depth": "basic",
    "max_results": 5,
    "days": 1
  }' -s | python3 - << 'PYTHON_SCRIPT'
import json
import sys
from datetime import datetime

try:
    data = json.load(sys.stdin)
    
    # 获取结果
    results = data.get('results', [])
    
    if not results:
        print("🔍 今天暂无新资讯")
        sys.exit(0)
    
    # 构建消息
    today = datetime.now().strftime("%Y年%m月%d日")
    message = f"🤖 **每日AI资讯**\n\n📅 {today}\n\n"
    
    for idx, item in enumerate(results[:5], 1):
        title = item.get('title', '无标题')
        url = item.get('url', '')
        snippet = item.get('content', '')[:150]  # 限制简介长度
        
        # 清理snippet
        snippet = snippet.replace('\n', ' ').replace('\r', ' ').strip()
        
        message += f"**{idx}. {title}**\n"
        message += f"{snippet}...\n"
        message += f"🔗 {url}\n\n"
    
    message += f"\n📊 来源: Tavily Search\n⏰ 推送时间: {datetime.now().strftime('%H:%M')}"
    
    print(message)
    
except json.JSONDecodeError as e:
    print(f"❌ JSON解析失败: {e}")
    sys.exit(1)
except Exception as e:
    print(f"❌ 错误: {e}")
    sys.exit(1)
PYTHON_SCRIPT
