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
§
克隆/迁移规约：当用户提及"克隆"或"迁移"hermes时，自动执行：1) 清理 profiles/clone-me/ 中大文件（删除 hermes-agent/ node/ checkpoints/ sessions/ logs/ cache/ state.db* cron/ 等），2) tar czf 放到 Windows 桌面（/mnt/c/Users/da/Desktop/hermes-clone-me.tar.gz），3) 附带使用说明。Profile 名固定为 clone-me，用 hermes profile create clone-me --clone-all 创建后清理。
§
RMVX Ace Scripts.rvdata2 格式：Marshal.dump(Array[[Integer id, String name, String code], ...])。Window_SaveFile 没有 file_ok? 方法（试图 alias 它会崩）。$game_message.add 是阻塞式弹出窗口，不适合背景静默保存。用 DataManager.save_game(slot_index) 直接写存档。
§
RPG Maker VX Ace 脚本修改铁律：Scripts.rvdata2 中 code 是 Zlib 压缩存储的，不是明文。修改前必须解压所有脚本，逐个核实每个方法名（$game_temp.in_battle → 实际应为 $game_party.in_battle；DataManager.max_savefiles → 实际应为 savefile_max）。重度魔改游戏（如 KingExit）会删除标准 API，不能假设方法存在。参考 game-modding/references/rpg-maker-vx-ace.md。