User wants Hermes CLI to auto-start when opening Ubuntu WSL terminal. Implemented via ~/.bashrc with HERMES_AUTO_STARTED guard.
§
用户游戏偏好：国产独立游戏（火山的女儿、活侠传等）、叙事驱动型、低难度、卡牌肉鸽、骰子类。Steam 中国区定价（¥ 为主要币种）。要求推荐时控制操作难度。
§
用户技术水平：熟悉 WSL/Python/命令行，能自主运行脚本和爬数据。正在研究 Unity Mono 游戏 mod（Pirates Gambit），目标是用 BepInEx+Harmony 调整金币和难度，不修改原文件。
§
用户沟通风格：直接、追求效率。当工具调用陷入循环卡死时，会明确说「停」并要求解释原因。不接受盲目重试或猜测 appid 的耗时操作。对方案评估理性，接受诚实的数据不确定性标注。
§
用户偏好：遇到连续失败/卡顿时，先停下来总结根因，提出干净方案，再执行。不要反复尝试不同工具/路径。"先把前面的原因都总结一下任何定一个初步方案再考虑执行"是用户的明确要求。
§
玩家使用 XDGAME 盗版版 超时空方舟 (Chrono Ark)，游戏路径 D:\mygit\QuarkPanTool\downloads\Chrono Ark\，Mod 路径 Mod\。Unity 2018.4.32f1 Mono。通过 dotnet 6.0 SDK 编译 C# Harmony 2.9 mod，引用 Assembly-CSharp.dll。mod 继承 ChronoArkMod.Plugin.ChronoArkPlugin，设置通过 ModManager.getModInfo(ModId).GetSetting("key") as SliderSetting 读取 Value 属性。
§
默认走 PLAN 模式：除非是 trivial 问题（如 1+1=？、简单格式说明、单文件小脚本），否则先写计划后执行。写计划时标注确定性、需要用户配合的步骤、前置条件。用户确认后再动手。
§
记忆自主管理：当记忆使用率≥80%时，我主动提出压缩方案让用户确认，不需用户提醒。方案需列出：当前条目、拟精简项、确认后执行。
§
Proactive system maintainer — initiates config optimization, disk cleanup, and backup sync unprompted. Decisive: prefers full auto-cleanup over selective review once given a categorized summary. Systems thinker: values automation (git sync, cron self-heal, auto cleanup). Chinese-native, comfortable with CLI/git/GitHub. Trusts automation with clear output summaries.