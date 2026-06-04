Steam API Key: 64462F349B2B2E6B941F086621471E6B。用于 steam-recommender skill。
§
DD1 盗版 D:\...\DarkestDungeon。WorkshopDL 下 Mod。
§
任务执行约束（硬规约）：任何工具调用返回失败/空结果后，立即检查 todo 中当前步骤标记。若已有≥1次失败记录，禁止自动重试——必须先输出 [STATUS] 报告（已尝试、失败原因、下一步方案），等待用户反馈后再继续。第一次失败时，在 todo 中标记当前步骤为 failed，并记录失败原因。PLAN 模式中须将失败处理策略写入步骤描述。
§
不用 SteamCMD，优先 WorkshopDL。smods.ru/ggntw/steamworkshop.download 不可靠。
§
XDGAME 盗版。Mod 需可配置；出问题先冲突分析。
§
Ghidra 11.3.2 + Frida MCP 已配置完毕，一键启动脚本在桌面 Start-MCP-Services.cmd。WSL→Windows 动态 IP 已配置。工作流：Ghidra→Frida→写 Mod。此项目已完结。
§
[HL] session-handoff skill 已建。PLAN 默认。SOUL.md 已简化。
§
测试/验证约束（硬规约）：当用户指令为"测试"、"验证"、"检查"等只读操作时，只调用只读工具（输出/读取/查询类），禁止任何写操作（写入文件、patch、cp/mv/rm/chmod等）。如需写文件才能解决问题，先输出诊断结果+写文件方案，等用户明确说"执行"再动手。