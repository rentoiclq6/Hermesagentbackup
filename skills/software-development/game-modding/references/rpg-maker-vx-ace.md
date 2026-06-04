# RPG Maker VX Ace 脚本修改 (Scripts.rvdata2)

## 数据结构

`Scripts.rvdata2` 是一个 `Marshal.dump` 的 Array，每个元素为：

```ruby
[section_id(Integer), name(String), code(String)]
```

**关键：`code` 是 Zlib 压缩后的二进制数据**，不是明文。

读写公式：

```ruby
require "zlib"

# 读取
data = Marshal.load(File.binread("Scripts.rvdata2"))
code_plain = Zlib::Inflate.inflate(entry[2]).force_encoding("UTF-8")

# 写入
compressed = Zlib::Deflate.deflate(code_plain)
new_entry = [random_id, "脚本名", compressed]
data.insert(position, new_entry)
File.binwrite("Scripts.rvdata2", Marshal.dump(data))
```

⚠️ **不要用 `Ruby 3.x` 序列化后直接给 VX Ace 用** — Ruby 3.x 的 Marshal 格式与 RPG Maker 内置的 Ruby 1.9 兼容，但需要注意编码处理（代码字符串应为 UTF-8 编码后 Zlib 压缩）。

## 脚本插入位置

标准 VX Ace 脚本结构（从上到下）：
1. 模块（Vocab, Sound, Cache, DataManager, SceneManager...）
2. 游戏对象（Game_Temp, Game_System, Game_Map, Game_Party...）
3. 精灵（Sprite_Base, Sprite_Character...）
4. 窗口（Window_Base, Window_SaveFile...）
5. 场景（Scene_Base, Scene_Map, Scene_Battle...）
6. ▼ メイン（Main 脚本 — 游戏入口）

**推荐插入点：紧接在所有类定义之后、▼ メイン 之前**（通常是列表最后几项之一）。这样所有类都已加载，你的别名（alias）不会因类未定义而失败。

## 别名模式（标准 VX Ace 写法）

```ruby
class Scene_Map
  alias auto_save_update update
  def update
    auto_save_update        # 调用原始方法
    $game_system.my_new_method   # 添加新逻辑
  end
end
```

这是最安全的扩展方式，与原脚本中其他别名兼容。

## ⚠️ 方法名核实铁律（该问题导致本文件诞生）

**重度魔改的游戏会大量删除/重命名标准 VX Ace 方法。以下是我们踩过的坑：**

| 方法/变量 | 标准 VX Ace | KingExit (实际) |
|-----------|-------------|-----------------|
| 战中标示 | `$game_temp.in_battle` | ❌ **不存在**，应改用 `$game_party.in_battle`（定义在 `Game_Unit#in_battle`） |
| 存档位数量 | `DataManager.max_savefiles` | ❌ **不存在**，应改用 `DataManager.savefile_max` |
| `Game_Temp` | 有大量属性和方法 | ✅ **大幅精简**，仅保留 `common_event_id` 和 `fade_type` |

## 🧠 旧存档兼容性问题（严重，Session 2026-05-19 多次踩坑）

**现象：** 脚本编译/加载无报错，但功能完全不触发。用户等待 5-10 分钟无反应。

**根因：** 加载旧存档时，新脚本添加的实例变量（`@auto_save_timer`、`@auto_save_switch` 等）**在 Marshal 恢复后的对象中不存在**，值为 `nil`。然后：

```ruby
return unless @auto_save_switch   # ← nil 是 falsy → 永远 return，脚本形同虚设
```

**修复模式：**

```ruby
# ❌ 错误（旧存档永远跳过）
def auto_save_update
  return unless @auto_save_switch
  ...
end

# ✅ 正确（兼容旧存档）
def auto_save_update
  @auto_save_timer ||= 0          # 旧存档 nil → 自动初始化
  @save_slot ||= 1
  @save_interval ||= 10800
  return if @auto_save_switch == false   # nil == false 为 false → 通过
  ...
end
```

**关键区别：** `return unless x` 会在 `x = nil` 时拦截（nil 是 falsy），而 `return if x == false` 只在显式设置为 `false` 时拦截，`nil` 会放行。

**何时需要这种防护：** 所有给已有存档设计的脚本功能。如果用户已经玩了一段时间才加 Mod，必须有惰性初始化。**这是最常见也最容易忽略的无声失败原因。**

**操作流程：** 每次写脚本前，用 Ruby 解压全部脚本，搜索确认每个调用的方法名真实存在：

```ruby
require "zlib"
data = Marshal.load(File.binread("Scripts.rvdata2"))
data.each_with_index do |entry, i|
  code = Zlib::Inflate.inflate(entry[2]).force_encoding("UTF-8")
  # 搜索方法定义
  puts "[#{i}] #{entry[1]}" if code.include?("def your_method_name")
  # 或搜索调用方式
  puts "[#{i}] #{entry[1]}" if code.include?("in_battle")
end
```

## 自动存档脚本实现（已验证可用的模板）

以下脚本在 **KingExit v3.0.2c** 上验证通过，每 3 分钟静默自动保存到 1 号槽位：

```ruby
class Game_System
  attr_accessor :auto_save_timer
  attr_accessor :auto_save_switch

  alias auto_save_init initialize
  def initialize
    auto_save_init
    @auto_save_timer = 0
    @auto_save_switch = true
    @save_slot = 1
    @save_interval = 10800      # 60fps × 60s × 3min = 10800 帧
  end

  def auto_save_update
    # ⚠️ 旧存档兼容：用 ||= 惰性初始化，用 == false 而非 unless
    @auto_save_timer ||= 0
    @save_slot ||= 1
    @save_interval ||= 10800
    return if @auto_save_switch == false   # nil 放行（旧存档）
    return if $game_map.interpreter.running?
    return if $game_party.in_battle        # ⚠️ 不是 $game_temp.in_battle！
    @auto_save_timer += 1
    if @auto_save_timer >= @save_interval
      do_auto_save
      @auto_save_timer = 0
    end
  end

  def do_auto_save
    return if $game_map.interpreter.running?
    return if $game_party.in_battle
    save_index = @save_slot - 1
    max_slots = DataManager.savefile_max   # ⚠️ 不是 max_savefiles！
    if save_index >= 0 && save_index < max_slots
      DataManager.save_game(save_index)    # 静默保存
    end
  end
end

class Scene_Map
  alias auto_save_update update
  def update
    auto_save_update
    $game_system.auto_save_update
  end
end
```

### 静默保存说明
- 成功时不调用 `$game_message.add`（避免弹框打断游戏）
- 只在出异常（如槽位无效）时提示
- 使用 `@save_slot = 1` 固定槽位，可修改为其他值

## ⭐ 安全模式：全局 rescue 包裹（Session 2026-05-19 引入）

> 任何会给旧存档添加新实例变量的脚本，应当在新方法入口处用 `||=` 处理旧存档不存在的变量，
> 并用 `rescue => err; # silent; end` 包裹全部新增逻辑，防止意外异常让游戏崩溃。

这是最重要的防护模式。KingExit 的踩坑过程：

```ruby
# 安全模式示例（auto_save_update）
def auto_save_update
  begin
    # ① 旧存档兼容：惰性初始化
    @auto_save_frame = 0 if @auto_save_frame.nil?
    @auto_save_enabled = true if @auto_save_enabled.nil?
    return unless @auto_save_enabled

    @auto_save_frame += 1
    return if $game_map.interpreter.running?
    return if $game_party.in_battle

    if @auto_save_frame >= @auto_save_interval
      DataManager.save_game(save_index)
      @auto_save_frame = 0
    end
  rescue => err
    # 静默吞掉——宁可不存档也不崩游戏
  end
end
```

**好处：** 即便方法名错了、变量类型不对、游戏状态异常，游戏本身不会崩溃。

## ⭐ 脚本别名命名规范

多个脚本可能 aliase 同一个方法。为了避免命名冲突，遵循以下规则：

| 场景 | 命名 | 示例 |
|------|------|------|
| 第一版 | `ff_方法名` 作为别名 | `alias ff_update_show_fast update` |
| 后续迭代 | 加版本后缀 | `alias auto_save_update_v3 update` |
| 独立功能 | 功能前缀 | `alias ff_wait wait`（fast-forward）|

命名冲突不会报错，只会导致某个别名静默失效。用唯一前缀是低成本的预防。

## ⭐ 帧率考虑

`@save_interval = 10800` 假设 `Graphics.frame_rate = 60`。但有些游戏会自定义帧率（40、30、20）。以下公式自动适应：

```ruby
@save_interval = Graphics.frame_rate * 60 * 3   # 3 分钟
```

但 `Graphics.frame_rate` 也可能在游戏运行时被修改。建议输出一次验证：

```ruby
p "Auto-save: #{@save_interval} frames = #{@save_interval / Graphics.frame_rate} seconds"
```

## ⭐ Alt 键快进/跳过文本脚本模板（KingExit 验证通过）

功能：按住 Alt 时文本瞬间显示 + 跳过翻页暂停 + 跳过事件等待指令。
松开 Alt 恢复正常。

```ruby
#==============================================================================
# Alt 键剧情快进/跳过
#==============================================================================

class Window_Message
  # 快进：文本瞬间出现
  alias ff_update_show_fast update_show_fast
  def update_show_fast
    ff_update_show_fast
    if Input.press?(:ALT)
      @show_fast = true
      @line_show_fast = true
    end
  end

  # 跳过换页暂停（按住 Alt 时不等人按确认）
  alias ff_input_pause input_pause
  def input_pause
    return if Input.press?(:ALT)
    ff_input_pause
  end
end

class Game_Interpreter
  # 跳过事件指令中的等待（\. \| 等）
  alias ff_wait wait
  def wait(duration)
    return if Input.press?(:ALT)
    ff_wait(duration)
  end
end
```

**行为说明：**
| 操作 | 效果 |
|------|------|
| 按住 Alt | 文本瞬间显示完 + 翻页不等人按确认 + 事件等待全部跳过 |
| 松开 Alt | 恢复正常阅读速度 |
| 遇到选项 | 正常等待选择，不会自动跳过 |

**三个 Hook 的作用：**
1. `update_show_fast`：每帧强制 `@show_fast = true`，文本一次性刷完（标准 VX Ace 的 `@show_fast` 只在按 C 键时设一次，换页后被 `clear_flags` 重置）
2. `input_pause`：跳过翻页后等待用户按确认的暂停
3. `wait`：跳过 `\.`（15帧延迟）、`\|`（60帧延迟）等事件指令中的等待

**已知限制：** 不会跳过文字以外的动画/移动/音效播放等事件指令（只跳过了显式的 `wait` 调用）。如果要深层跳过整个事件，需要额外加 `@index += 读秒步数` 逻辑在 `command_112`～`command_115` 处。

## 🔍 无声失败调试清单

脚本编译/加载无报错但功能不触发时，按优先级排查：

1. **旧存档兼容性**（最常见）→ 检查实例变量是否为 nil（`return unless @var` 会静默跳过）。用 `||=` 惰性初始化 + `== false` 替代 `unless`。
2. **方法名不存在** → 脚本实际会崩溃，但 `DataManager.save_game` 的 `rescue` 可能吞掉异常导致无声失败。用全局搜索验证每个方法名。
3. **条件过于严格** → 检查 `return if` 条件是否意外覆盖正常场景。例如战斗检查用了不存在的全局/不正确的返回语义。
4. **被其他脚本重设** → 搜索其他脚本中是否对 `$game_system` 调用了 `initialize` 或直接设置了 `@auto_save_timer = 0`。
5. **帧率差异** → 该游戏可能自定义了 `Graphics.frame_rate`。用以下方式检查：
   ```ruby
   p "FPS: #{Graphics.frame_rate}"
   ```
   或者在 Main 前插入临时脚本用 msgbox 查看。
6. **全局 rescue 已吞掉异常** → 检查脚本是否用了 `rescue => err; # silent`。如果怀疑某处抛异常但游戏没崩，暂时去掉 rescue 让它崩一次看错误信息。
7. **文件路径不对** → 检查修改的 `Scripts.rvdata2` 是否真正被游戏读取。有些用户会在不同目录反复复制。确认游戏 exe 所在目录的 Data/ 子文件夹中的才是生效文件。
