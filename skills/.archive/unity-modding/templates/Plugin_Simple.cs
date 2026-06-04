using System;
using System.Reflection;
using BepInEx;
using HarmonyLib;
using UnityEngine;

namespace MyMod
{
    [BepInPlugin("com.mymod.id", "My Mod", "1.0.0")]
    public class Plugin : BaseUnityPlugin
    {
        // CHANGE THESE VALUES
        internal static float CoinMultiplier = 3f;
        internal static float RepairMultiplier = 0.3f;

        private void Awake()
        {
            Logger.LogInfo("=== My Mod v1.0 ===");
            Logger.LogInfo("Coin multiplier: " + CoinMultiplier + "x");

            var harmony = new Harmony("com.mymod.id");

            // Auto-scan: find all methods containing Coin+Add/Gain/Earn
            foreach (var type in Assembly.GetAssembly(typeof(GameManager_New)).GetTypes())
            {
                foreach (var method in type.GetMethods(
                    BindingFlags.Instance | BindingFlags.Static |
                    BindingFlags.Public | BindingFlags.NonPublic))
                {
                    var name = method.Name;
                    if (name.IndexOf("Coin") >= 0 &&
                        (name.IndexOf("Add") >= 0 ||
                         name.IndexOf("Gain") >= 0 ||
                         name.IndexOf("Earn") >= 0))
                    {
                        try
                        {
                            harmony.Patch(method,
                                prefix: new HarmonyMethod(typeof(CoinHooks), "MultiplyCoinArgs"));
                            Logger.LogInfo("  Hooked: " + type.Name + "." + name);
                        }
                        catch { }
                    }
                }
            }

            Logger.LogInfo("Mod loaded!");
        }
    }

    public static class CoinHooks
    {
        // Multiply any int argument that looks like a coin value
        public static void MultiplyCoinArgs(ref object[] __args)
        {
            for (int i = 0; i < __args.Length; i++)
            {
                if (__args[i] is int)
                {
                    int val = (int)__args[i];
                    if (val > 0 && val < 1000)
                    {
                        int old = val;
                        __args[i] = Mathf.RoundToInt(val * Plugin.CoinMultiplier);
                        if (old != (int)__args[i])
                        {
                            Debug.Log("[Mod] Coin " + old + " -> " + __args[i]);
                        }
                    }
                }
            }
        }
    }
}
