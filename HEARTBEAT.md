# HEARTBEAT.md

如果收到系统事件"推送AI新闻"，执行以下操作：

1. 运行脚本：`python3 daily-ai-news.py`
2. 脚本会：
   - 从Tavily API获取最新AI新闻
   - 验证每个链接的有效性
   - 只发送可访问的链接
   - 通过message工具发送到当前飞书会话

定时任务配置：
- 任务名称：每日AI新闻推送
- 执行时间：每天早上8:30
- 时区：Asia/Shanghai
- 状态：已启用
