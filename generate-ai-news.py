#!/usr/bin/env python3
"""
每日AI资讯推送机器人（完全按规范实现）
"""
import json
import subprocess
import os
import re
from datetime import datetime

def clean_snippet(text, max_length=200):
    """清理文本，在句子边界截断，保证1-2句完整的话"""
    # 移除HTML标签
    text = re.sub('<[^<]+?>', ' ', text)
    # 移除多余空白
    text = re.sub(r'\s+', ' ', text).strip()
    
    # 如果文本不太长，直接返回
    if len(text) <= max_length:
        return text
    
    # 在句子边界截断（优先中文标点，然后是英文标点）
    for i in range(max_length, 0, -1):
        if text[i] in ['。', '？', '！', '；', '、', '，', '.', '?', '!', ';', ',']:
            return text[:i+1].strip()
    
    # 如果找不到标点，在空格处截断
    for i in range(max_length, 0, -1):
        if text[i] == ' ':
            return text[:i].strip()
    
    return text[:max_length].strip()

def validate_url(url, timeout=10):
    """验证URL是否可访问"""
    try:
        cmd = [
            'curl', '-s', '-o', '/dev/null', 
            '-w', '%{http_code}',
            '-m', str(timeout),
            '--connect-timeout', '5',
            '--max-redirs', '3',
            '-L',
            url
        ]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout+5)
        status_code = result.stdout.strip()
        return status_code == '200'
    except Exception:
        return False

def search_ai_news():
    """搜索AI新闻 - 使用指定来源网站"""
    print(f"[{datetime.now().strftime('%H:%M:%S')}] 🔍 搜索AI新闻...")
    
    # 优先网站
    priority_sites = [
        'artificialintelligence-news.com',
        'venturebeat.com',
        'theverge.com',
        'techcrunch.com',
        'wired.com',
        'technologyreview.com'
    ]
    
    cmd = [
        'curl', '-X', 'POST', 'https://api.tavily.com/search',
        '-H', 'Content-Type: application/json',
        '-d', json.dumps({
            "api_key": "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",
            "query": "AI artificial intelligence news 2026 最新",
            "search_depth": "advanced",
            "max_results": 12,
            "days": 7,
            "include_answer": True
        }),
        '-s'
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    data = json.loads(result.stdout)
    
    valid_news = []
    checked_urls = set()
    
    for item in data.get('results', []):
        url = item.get('url', '').strip()
        if not url or url in checked_urls:
            continue
        checked_urls.add(url)
        
        # 跳过YouTube
        if 'youtube.com' in url or 'youtu.be' in url:
            continue
        
        # 检查是否来自优先网站
        domain_match = any(site in url for site in priority_sites)
        if not domain_match:
            continue
        
        if validate_url(url, timeout=8):
            valid_news.append(item)
        
        if len(valid_news) >= 3:
            break
    
    return valid_news

def search_papers():
    """搜索AI论文 - arXiv, Papers with Code, OpenReview等"""
    print(f"[{datetime.now().strftime('%H:%M:%S')}] 🔍 搜索AI论文...")
    
    paper_sources = [
        'arxiv.org',
        'paperswithcode.com',
        'openreview.net',
        'huggingface.co/papers'
    ]
    
    cmd = [
        'curl', '-X', 'POST', 'https://api.tavily.com/search',
        '-H', 'Content-Type: application/json',
        '-d', json.dumps({
            "api_key": "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",
            "query": "arXiv papers AI machine learning CVPR NeurIPS ICML 2026",
            "search_depth": "advanced",
            "max_results": 12
        }),
        '-s'
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    data = json.loads(result.stdout)
    
    valid_papers = []
    checked_urls = set()
    
    for item in data.get('results', []):
        url = item.get('url', '').strip()
        if not url or url in checked_urls:
            continue
        checked_urls.add(url)
        
        # 检查来源
        source_match = any(source in url for source in paper_sources)
        if not source_match:
            continue
        
        if validate_url(url, timeout=8):
            valid_papers.append(item)
        
        if len(valid_papers) >= 3:
            break
    
    return valid_papers

def search_trends():
    """搜索AI行业动态 - 公司博客、开源生态等"""
    print(f"[{datetime.now().strftime('%H:%M:%S')}] 🔍 搜索AI动态...")
    
    trend_sources = [
        'openai.com/blog',
        'deepmind.google',
        'anthropic.com/news',
        'ai.meta.com/blog',
        'github.com/trending',
        'huggingface.co/models'
    ]
    
    cmd = [
        'curl', '-X', 'POST', 'https://api.tavily.com/search',
        '-H', 'Content-Type: application/json',
        '-d', json.dumps({
            "api_key": "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",
            "query": "AI trends OpenAI Anthropic Meta Google GitHub trending 2026",
            "search_depth": "advanced",
            "max_results": 10
        }),
        '-s'
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    data = json.loads(result.stdout)
    
    valid_trends = []
    checked_urls = set()
    
    for item in data.get('results', []):
        url = item.get('url', '').strip()
        if not url or url in checked_urls:
            continue
        checked_urls.add(url)
        
        # 检查来源
        source_match = any(source in url for source in trend_sources)
        if not source_match:
            continue
        
        if validate_url(url, timeout=8):
            valid_trends.append(item)
        
        if len(valid_trends) >= 3:
            break
    
    return valid_trends

def main():
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 开始搜索AI资讯...")
    
    try:
        # 搜索三类内容
        news = search_ai_news()
        papers = search_papers()
        trends = search_trends()
        
        # 检查是否有内容
        if not (news or papers or trends):
            print("❌ 未找到任何有效内容")
            return None

        # 构建消息 - 按照规范格式
        today = datetime.now().strftime("%Y年%m月%d日")
        message = f"🤖 每日AI资讯\n📅 {today}\n\n"
        
        # 1️⃣ AI新闻
        if news:
            message += "📰 AI新闻\n"
            for idx, item in enumerate(news, 1):
                title = item.get('title', '无标题').strip()
                url = item.get('url', '')
                content = item.get('content', '')
                snippet = clean_snippet(content, max_length=200)
                message += f"1️⃣ {title}\n"
                message += f"📄 {snippet}\n"
                message += f"🔗 {url}\n\n"
            message += "\n"
        
        # 2️⃣ 顶级论文/会议论文
        if papers:
            message += "📚 最新论文 / 顶会研究\n"
            for idx, item in enumerate(papers, 1):
                title = item.get('title', '无标题').strip()
                url = item.get('url', '')
                content = item.get('content', '')
                snippet = clean_snippet(content, max_length=200)
                message += f"1️⃣ {title}\n"
                message += f"📄 {snippet}\n"
                message += f"🔗 {url}\n\n"
            message += "\n"
        
        # 3️⃣ AI行业动态
        if trends:
            message += "⚡ AI行业动态\n"
            for idx, item in enumerate(trends, 1):
                title = item.get('title', '无标题').strip()
                url = item.get('url', '')
                content = item.get('content', '')
                snippet = clean_snippet(content, max_length=200)
                message += f"1️⃣ {title}\n"
                message += f"📄 {snippet}\n"
                message += f"🔗 {url}\n\n"
        
        # 添加来源和时间
        message += "💡 信息来源：AI-News / TechCrunch / MIT Tech Review / arXiv / HuggingFace\n"
        message += f"⏰ 推送时间：08:30"

        # 保存到文件
        output_dir = "/Users/mac/.openclaw/workspace"
        timestamp_file = os.path.join(output_dir, ".ai-news-timestamp")
        message_file = os.path.join(output_dir, ".ai-news-message")

        with open(message_file, 'w', encoding='utf-8') as f:
            f.write(message)

        with open(timestamp_file, 'w', encoding='utf-8') as f:
            f.write(datetime.now().isoformat())

        total = len(news) + len(papers) + len(trends)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 消息已生成，等待发送...")
        print(f"✅ 总计: {total}条 (新闻{len(news)} | 论文{len(papers)} | 动态{len(trends)})")
        return message

    except json.JSONDecodeError as e:
        print(f"❌ JSON解析失败: {e}")
        return None
    except Exception as e:
        print(f"❌ 错误: {e}")
        import traceback
        traceback.print_exc()
        return None

if __name__ == "__main__":
    main()
