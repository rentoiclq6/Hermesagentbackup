Steam API Key: 64462F349B2B2E6B941F086621471E6B。用于 steam-recommender skill。
§
DD1/XDGAME盗版。WorkshopDL优先于SteamCMD，smods.ru不可靠。Mod可配置，出问题先冲突分析。
§
执行硬规约：
【失败】工具失败/空→查todo标记。≥1次失败→停，输出[STATUS](已试/原因/方案)，等用户。首次失败→标记failed。
【跨环境自检】WSL→Win文件(.bat/.ps1/.reg/配置)交付前强制三问：WSL可验证？有诊断命令？有降级方案？任一否=阻断交付。
【双路径】PLAN必规划：WSL验证方案(优先)+Win脚本(降级,[UNTESTED])。Win脚本交付前须cmd.exe /c验证语法/PS解析；GUI行为无法验证须标注。
【可信度绑定】WSL内脚本=[VERIFIED];Win脚本/配置=[UNTESTED];curl/web=[VERIFIED];猜测诊断=[SPECULATIVE]。按类型自动绑定。
【Win试错上限】同一Win交付物最多改2次。第3次→弃原方案，换WSL验证或要完整报错。
【只读约束】测试/验证/检查→只读工具。需写→先出方案等确认。
【GUI盲区】Windows GUI行为(窗口/闪退/双击)我完全不可见→涉及此一律标注无法验证+提供cmd诊断命令。
§
[HL] session-handoff skill 已建。PLAN 默认。SOUL.md 已简化。
§
克隆/迁移规约：当用户提及"克隆"或"迁移"hermes时，自动执行：1) 清理 profiles/clone-me/ 中大文件（删除 hermes-agent/ node/ checkpoints/ sessions/ logs/ cache/ state.db* cron/ 等），2) tar czf 放到 Windows 桌面（/mnt/c/Users/da/Desktop/hermes-clone-me.tar.gz），3) 附带使用说明。Profile 名固定为 clone-me，用 hermes profile create clone-me --clone-all 创建后清理。
§
RMVX Ace Scripts.rvdata2 格式：Marshal.dump(Array[[Integer id, String name, String code], ...])。Window_SaveFile 没有 file_ok? 方法（试图 alias 它会崩）。$game_message.add 是阻塞式弹出窗口，不适合背景静默保存。用 DataManager.save_game(slot_index) 直接写存档。
§
RPG Maker VX Ace 脚本修改铁律：Scripts.rvdata2 中 code 是 Zlib 压缩存储的，不是明文。修改前必须解压所有脚本，逐个核实每个方法名（$game_temp.in_battle → 实际应为 $game_party.in_battle；DataManager.max_savefiles → 实际应为 savefile_max）。重度魔改游戏（如 KingExit）会删除标准 API，不能假设方法存在。参考 game-modding/references/rpg-maker-vx-ace.md。
§
Git 备份法：`cd ~/.hermes && git init && git add -A && git commit -m "..." && git remote add origin <url> && git push`。关键：.gitignore 排除 .env/hermes-agent/node/checkpoints/sessions/logs/cache/state.db*；用 classic PAT（ghp_）不要 fine-grained PAT（403 坑）；`git config credential.helper store` + `git credential-store store` 缓存凭证。用于持续增量同步，与 tar.gz 克隆法互补。
§
WSL路径解析：用户给 Windows 盘符路径（如 F:\xxx）时，必须先用 `ls /mnt/` 检查所有已挂载的磁盘，不要只搜 C:/D:。外接硬盘/U 盘可能挂载为其他盘符（F:/G:/H: 等）。搜索文件卡住时应先检查对应 /mnt/[盘符] 是否存在。
§
liteLLM 网关已部署。配置文件：C:\...\Python312\Lib\site-packages\litellm\config.yaml。入口：general(flash直连)、v4-flash(双provider HA)、v4-pro(双provider HA+降级flash)。自带Anthropic格式翻译(/v1/messages)。OpenRouter备用需OPENROUTER_API_KEY环境变量。从Windows CMD启动。