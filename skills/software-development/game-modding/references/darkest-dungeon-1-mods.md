# Darkest Dungeon 1 — Workshop Mods Reference

AppID: `262060`

## Essential QoL Mods

| Name | Workshop ID | Author | Subscribers | Notes |
|------|------------|--------|-------------|-------|
| Level Restrictions Removal | 840391233 | Maester Silvio | 523K | 去除等级限制 |
| Stacking Inventory | 840387268 | Maester Silvio | 483K | 物品堆叠(限量) |
| Faster Scouting | 1419394405 | Rin | — | 侦查加速 |
| Faster Walking | 946034275 | Ox | 312K | 走路加速 |
| x2 Combat Speed | 1483754805 | o'night | 249K | 战斗2倍速(非Steam版可能无效) |
| Simple Auto Supplies | 3304308584 | MightyLater | — | 自动补给 |
| 我全都要_I Want Them ALL | 2862923606 | Butterf9 | — | 物品堆叠无上限(与我全都要类冲突) |
| 4 Trinkets+24 slot inventory | 1439812609 | LUKA | — | 4饰品格+24背包(与我全都要冲突) |
| 7 Quirks, 7 Lockable | 1111555280 | Whisper The Wolf | — | 黄癖红癖各7个 |

## Chinese Localization & Font

| Name | Workshop ID | Author | Notes |
|------|------------|--------|-------|
| Mod 简体中文化 | 1741850027 | LUKA | 兼容众多Mod的汉化 |
| 中文字体重做(Chinese Font Rework) | 2814682822 | EKG | 字体替换 |

## Class Mods

| Name | Workshop ID | Author | Notes |
|------|------------|--------|-------|
| 「莫德凯撒」Mordekaiser Class | 3144299757 | Kaze* | 超模职业，有Rebalanced版本(3181197308)和补丁(3659966915) |
| Marvin Seo's Falconer Class Mod | 1089257023 | Marvin Seo | 需Shared Assets前置(1907321071) |
| Marvin Seo's Lamia Class Mod | 1130829365 | Marvin Seo | 同上 |
| The Twilight Knight | 1154908982 | Balgin Stondraeg | 328K subscribers |
| The Soulforged Class Mod | 3680778735 | — | 近期热门 |

## Curio Hints (奇物互动提示)

| Name | Workshop ID | Author | Notes |
|------|------------|--------|-------|
| Curio Hints (原版) | 929763488 | Dirtside | 原版地牢 |
| Curio Hints New Update (含CC) | 1172190166 | Blaink | 中文+猩红宫廷 |
| Know Your Curio | 2806761466 | Franisz | 原版+详细 |
| Know Your Curio (Area Expantion) | 3215254893 | Zagreus | 区域扩展 |

## Hero Revival (复活)

| Name | Workshop ID | Author | Subscribers | Notes |
|------|------------|--------|-------------|-------|
| Revive Dead (Vanilla) | 1252196367 | Teddy | 24K | 99%复活事件，不支持CC/Shieldbreaker DLC |
| Resurrect a Hero Every Week | 2842685756 | I Shall Destroy Anime | 6K | 每周复活 |
| Resurrection Event-复活事件 | 3173750591 | Zagreus | — | 中文，DLC兼容性更好 |
| 死而复生 Resurrection event | 2511735990 | 蕞嗳 | — | 备选 |

## DD+ Overhaul

| Name | Workshop ID | Notes |
|------|------------|-------|
| Manor and Darkest Dungeon Plus Revived Patch | 3723353789 | DD+大修 |
| The Fiend Festival - New Dungeon | 3669966489 | 新地牢+饰品 |
| The Crag Fiend Miniboss | 3662096012 | 新Boss |

## UI / Audio

| Name | Workshop ID | Notes |
|------|------------|-------|
| 明朗大地UI | 3724526833 | 中文UI美化 |
| Music For Bosses | 3724446232 | Boss战BGM |
| Modded Dungeons Music Fix (Manor) | 3723078566 | Mod音乐修复 |

## Known Installation Pitfalls

1. **Folder naming**: Avoid `「」` brackets, full-width chars, or pure Chinese folder names → rename to ASCII
2. **Language code**: `<Language>chinese</Language>` is INVALID → must be `schinese` (or `english`, `tchinese`, etc.)
3. **Visibility**: `<Visibility>private</Visibility>` causes DD to skip → change to `public`
4. **time_scale_combat**: x2 Combat Speed mods may not work on non-Steam/cracked DD versions
