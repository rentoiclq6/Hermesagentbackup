# Chrono Ark 血雾等级修改 & 多层对象访问

## 问题

血雾等级（BloodyMist.Level）不暴露在简单的静态 Property 上，而是嵌套在游戏内存状态对象中。

## 访问链

```
SaveManager.savemanager (静态单例)
  └── TempSave (实例字段, TempSaveData)
      └── bMist (实例字段, BloodyMist)
          └── Level (实例字段, Int32)
```

## 代码实现

```csharp
// 字段缓存（在 Initialize 中获取一次）
var bmType = AccessTools.TypeByName("BloodyMist");
var levelField = bmType.GetField("Level", BindingFlags.Public | BindingFlags.Instance);
var tsdType = AccessTools.TypeByName("TempSaveData");
var bMistField = tsdType.GetField("bMist", BindingFlags.Public | BindingFlags.Instance);

// 写入（在 ModSetting 变化时调用）
void ApplyBloodyMistLevel()
{
    var smType = AccessTools.TypeByName("SaveManager");
    var smField = smType.GetField("savemanager", BindingFlags.Public | BindingFlags.Static);
    var smInstance = smField.GetValue(null);
    var tempSaveField = smType.GetField("TempSave", BindingFlags.Public | BindingFlags.Instance);
    var tempSave = tempSaveField.GetValue(smInstance);
    var bmInstance = bMistField.GetValue(tempSave);
    levelField.SetValue(bmInstance, newLevel);
}
```

## ChromoArkMod.json 设置条目

```json
{
    "SettingType": "SliderSetting",
    "SettingKey": "BloodyMistLevel",
    "DisplayName": ".../BloodyMistLevel/DisplayName",
    "Description": ".../BloodyMistLevel/Description",
    "InitValue": 0,
    "Max": 50,
    "Min": 0,
    "StepSize": 1
}
```

## 注意事项

- 血雾等级修改仅在「当前游戏会话」中生效，存档时游戏会保存当前值
- 设置中调为 0 表示「不修改」，保持当前等级不变
- `SaveManager.savemanager` 可能为 null（游戏场景未加载时），需添加空值检查
