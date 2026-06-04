using System;
using System.Reflection;
using BepInEx;
using HarmonyLib;
using UnityEngine;

namespace MyGameMod
{
    [BepInPlugin("com.mygame.mod", "MyGame Mod", "1.0.0")]
    public class Plugin : BaseUnityPlugin
    {
        // === CONFIG: Change these values ===
        internal static float CoinMultiplier = 3f;
        internal static float RepairMultiplier = 0.3f;
        // ====================================

        private void Awake()
        {
            Logger.LogInfo("=== MyGame Mod v1.0 ===");
            Logger.LogInfo("Coin multiplier: " + CoinMultiplier + "x");

            var harmony = new Harmony("com.mygame.mod");

            // Scan for all Coin-related methods (discovery phase)
            var gameAsm = Assembly.GetAssembly(typeof(GameManager_New)); // Change GameManager_New to your game's main class
            foreach (var type in gameAsm.GetTypes())
            {
                foreach (var method in type.GetMethods(BindingFlags.Instance | BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic))
                {
                    var name = method.Name;
                    if (name.IndexOf("Coin") >= 0 || name.IndexOf("coin") >= 0)
                    {
                        var parms = method.GetParameters();
                        var parmStr = "";
                        foreach (var p in parms)
                            parmStr += p.ParameterType.Name + " " + p.Name + ", ";
                        Logger.LogInfo("  Found: " + type.Name + "." + name + "(" + parmStr + ") -> " + method.ReturnType.Name);
                    }
                }
            }

            // Hook: OnCoinAdded (common coin entry point)
            try
            {
                var method = typeof(GameManager_New).GetMethod("OnCoinAdded",
                    BindingFlags.Instance | BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
                if (method != null)
                {
                    harmony.Patch(method, prefix: new HarmonyMethod(typeof(Hooks), "MultiplyFirstIntArg"));
                    Logger.LogInfo("  Patched: OnCoinAdded");
                }
            }
            catch (Exception ex) { Logger.LogWarning("Patch failed: " + ex.Message); }

            // Hook: GetWheelCoinEarnings (wheel/spin reward)
            try
            {
                var method = typeof(GameManager_New).GetMethod("GetWheelCoinEarnings",
                    BindingFlags.Instance | BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
                if (method != null)
                {
                    harmony.Patch(method, postfix: new HarmonyMethod(typeof(Hooks), "MultiplyIntResult"));
                    Logger.LogInfo("  Patched: GetWheelCoinEarnings");
                }
            }
            catch (Exception ex) { Logger.LogWarning("Patch failed: " + ex.Message); }

            Logger.LogInfo("Mod loaded! Check BepInEx/LogOutput.log for details.");
        }
    }

    public static class Hooks
    {
        // Prefix: multiply first int parameter
        public static void MultiplyFirstIntArg(ref int __0)
        {
            __0 = Mathf.RoundToInt(__0 * Plugin.CoinMultiplier);
        }

        // Postfix: multiply int return value
        public static void MultiplyIntResult(ref int __result)
        {
            __result = Mathf.RoundToInt(__result * Plugin.CoinMultiplier);
        }
    }
}
