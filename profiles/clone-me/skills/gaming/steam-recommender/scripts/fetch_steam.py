#!/usr/bin/env python3
"""
Steam 游戏数据采集脚本（通用版）
用法：
  python3 fetch_steam.py                              # 默认：卡牌肉鸽
  python3 fetch_steam.py --type rpg --out rpg.json    # 自定义类型+输出
  python3 fetch_steam.py --terms "开放世界,生存建造"  --out survival.json
  python3 fetch_steam.py --genre survival              # 预设类型（survival/rpg/horror/farming）

输出目录：~/.hermes/cache/

注意：此脚本在用户本地机器上运行（非 Hermes sandbox），不会触发工具审批。
"""
import json, time, urllib.request, urllib.parse, os, argparse

# === 预设搜索词库（按类型）===
PRESETS = {
    "card": [
        "deckbuilder", "card roguelike", "牌组构建", "卡牌肉鸽",
        "roguelike deck", "Slay the Spire", "Balatro", "Monster Train",
        "Griftlands", "Wildfrost", "Inscryption", "Dicey Dungeons",
        "Peglin", "骰子 roguelike", "麻将 roguelike", "卡牌 构筑",
    ],
    "survival": [
        "survival crafting", "生存建造", "open world survival",
        "base building", "Raft", "Valheim", "The Forest", "Rust",
        "Subnautica", "Grounded", "Palworld", "Enshrouded",
        "V Rising", "方舟", "森林", "深海迷航",
    ],
    "rpg": [
        "RPG open world", "角色扮演", "action RPG", "回合制 RPG",
        "Elden Ring", "Baldur Gate", "Cyberpunk", "Witcher",
        "Skyrim", "Fallout", "Persona", "Final Fantasy",
        "Divinity", "Pillars of Eternity", "老头环", "黑神话",
    ],
    "horror": [
        "horror game", "恐怖游戏", "survival horror", "psychological horror",
        "Resident Evil", "Silent Hill", "Outlast", "Amnesia",
        "Phasmophobia", "Dead Space", "Alan Wake", "Lethal Company",
        "生化危机", "逃生",
    ],
    "farming": [
        "farming sim", "Stardew Valley", "星露谷",
        "cozy game", "life sim", "Harvest Moon", "Story of Seasons",
        "My Time at", "Rune Factory", "Sun Haven", "Coral Island",
        "牧场物语", "模拟农场", "休闲种田", "Graveyard Keeper",
        "Dinkum", "Farm Together", "Fae Farm", "Wylde Flowers",
        "Spiritfarer", "Ooblets", "Slime Rancher",
    ],
    "strategy": [
        "strategy game", "tactical", "Civilization", "XCOM",
        "Total War", "Age of Wonders", "Into the Breach", "FTL",
        "三国志", "文明", "Fire Emblem", "Wargroove",
        "Triangle Strategy", "Crusader Kings", "Stellaris",
        "Hearts of Iron", "Europa Universalis", "Age of Empires",
        "Command & Conquer", "StarCraft", "帝国时代", "红色警戒",
    ],
    "puzzle": [
        "puzzle game", "解谜", "mystery", "侦探", "推理",
        "The Witness", "Portal", "Baba Is You", "Return of the Obra Dinn",
        "Outer Wilds", "The Talos Principle", "Gorogoa", "Unpacking",
        "A Little to the Left", "Viewfinder", "Chants of Sennaar",
        "Cocoon", "密室逃脱", "山河旅探", "疑案追声",
    ],
    "roguelike": [
        "roguelike", "roguelite", "肉鸽",
        "Hades", "Dead Cells", "Enter the Gungeon", "Risk of Rain",
        "The Binding of Isaac", "Returnal", "Nuclear Throne",
    ],
}

CACHE_DIR = os.path.expanduser("~/.hermes/cache")

def api(path, **params):
    url = f"https://store.steampowered.com/api/{path}"
    if params:
        url += "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": "SteamCache/1.0"})
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read())

def main():
    p = argparse.ArgumentParser(description="Steam 游戏数据采集")
    p.add_argument("--type", default="card", help="预设类型: card/survival/rpg/horror/farming/strategy/roguelike")
    p.add_argument("--terms", help="自定义搜索词，逗号分隔（覆盖 --type）")
    p.add_argument("--out", help="输出文件名（默认 steam_TYPE.json）")
    p.add_argument("--sleep", type=float, default=0.5, help="请求间隔秒数")
    args = p.parse_args()

    # 解析搜索词
    if args.terms:
        terms = [t.strip() for t in args.terms.split(",") if t.strip()]
    elif args.type in PRESETS:
        terms = PRESETS[args.type]
    else:
        print(f"未知类型: {args.type}，可用: {list(PRESETS.keys())}")
        print("或使用 --terms 自定义搜索词")
        return

    # 输出路径
    out_name = args.out or f"steam_{args.type}.json"
    out_path = os.path.join(CACHE_DIR, out_name)
    os.makedirs(CACHE_DIR, exist_ok=True)

    print(f"类型: {args.type} | 搜索词数: {len(terms)} | 输出: {out_path}")
    print()

    # Step 1: 收集 appid
    seen = set()
    app_ids = []
    for term in terms:
        try:
            data = api("storesearch", term=term, cc="cn", l="schinese")
            for item in data.get("items", []):
                aid = str(item["id"])
                if aid not in seen:
                    seen.add(aid)
                    app_ids.append(aid)
        except Exception as e:
            print(f"  [skip] {term}: {e}")
        time.sleep(args.sleep)
    print(f"收集到 {len(app_ids)} 个 appid")

    # Step 2: 批量获取详情
    games = []
    for i, aid in enumerate(app_ids):
        try:
            data = api("appdetails", appids=aid, cc="cn", l="schinese")
            val = data.get(aid, {})
            if not val.get("success"):
                continue
            d = val["data"]
            price = d.get("price_overview") or {}
            reviews = d.get("reviews") if isinstance(d.get("reviews"), dict) else {}
            games.append({
                "appid": int(aid),
                "name": d.get("name", ""),
                "price_cny": price.get("final", 0) / 100,
                "price_orig_cny": price.get("initial", 0) / 100,
                "release_date": d.get("release_date", {}).get("date", ""),
                "review_score": reviews.get("score_desc", ""),
                "review_total": reviews.get("total", 0),
                "genres": [g["description"] for g in d.get("genres", [])],
                "tags": list(d.get("tags", {}).values())[:8] if isinstance(d.get("tags"), dict) else [],
                "short_desc": (d.get("short_description", "") or "")[:200],
                "header_img": d.get("header_image", ""),
            })
        except Exception:
            pass
        if (i+1) % 5 == 0:
            time.sleep(args.sleep)
            print(f"  进度: {i+1}/{len(app_ids)} ({len(games)} 条有效)")

    # Step 3: 排序保存
    games.sort(key=lambda g: g["release_date"] or "0000", reverse=True)

    result = {
        "fetched_at": time.strftime("%Y-%m-%d %H:%M:%S"),
        "type": args.type,
        "count": len(games),
        "games": games,
    }

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)

    print(f"\n完成！{len(games)} 条游戏数据 → {out_path}")
    print(f"文件大小: {os.path.getsize(out_path)} bytes")

    # 展示最近 10 条
    print(f"\n=== 最近 10 款 ===")
    for g in games[:10]:
        print(f"  {g['release_date']:12s} | ¥{g['price_cny']:6.1f} | {g['review_score']:10s} | {g['name']}")

if __name__ == "__main__":
    main()
